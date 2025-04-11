#!/bin/bash

# Check  DBID 
if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 DBID Password"
    exit 1
fi

DBID=$1
PASSWORD=$2

# Reset the database password
echo "Resetting password for DBID: $DBID..."
DBHOST=$(aws rds describe-db-instances --db-instance-identifier $DBID | jq -r .DBInstances[].Endpoint.Address)

# Check if DBHOST was fetched successfully
if [[ -z "$DBHOST" ]]; then
    echo "Error: Failed to fetch DB host details."
    exit 1
fi

aws rds modify-db-instance --db-instance-identifier $DBID --master-user-password "$PASSWORD" --apply-immediately > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to reset the database password."
    exit 1
fi

echo "Password reset successfully. Waiting for changes to apply..."
sleep 60  # Wait 1 minute to  reset 

# PostgreSQL connection details
USER="JNJADMIN"
DB="postgres"
PORT="5432"
export PGPASSWORD=$PASSWORD

# Connection checks
PSQL_CMD="psql -h $DBHOST -U $USER -d $DB -p $PORT"
if ! $PSQL_CMD -c "SELECT 1;" > /dev/null 2>&1; then
    echo "Error: Unable to connect to the database with the password."
    exit 1
fi
echo "Connection successful. Running queries..."

# Check for any user with '_dre_readonly'
echo "Checking for users with '_dre_readonly' ..."
USER_CHECK_QUERY="SELECT rolname FROM pg_roles WHERE rolname LIKE '%_dre_readonly';"
USER_CHECK_RESULT=$($PSQL_CMD -tAc "$USER_CHECK_QUERY")
echo "User check result: $USER_CHECK_RESULT"

# If no user is found, prompt the user to create a readonly user
if [[ -z "$USER_CHECK_RESULT" ]]; then
    echo "No user found with '_dre_readonly'."
    read -p "Would you like to create a readonly user now? (yes/no): " RESPONSE
    if [[ "$RESPONSE" == "yes" ]]; then
[O        read -p "Enter the readonly username to create: " NEW_USER
        read -sp "Enter the password for the readonly user: " NEW_USER_PASSWORD
        echo

        # Create the new readonly user
        echo "Creating readonly user: $NEW_USER..."
        CREATE_USER_QUERY="CREATE USER $NEW_USER WITH PASSWORD '$NEW_USER_PASSWORD';"
        if ! $PSQL_CMD -c "$CREATE_USER_QUERY" > /dev/null 2>&1; then
            echo "Error: Failed to create user $NEW_USER."
            exit 1
        fi

        echo "User $NEW_USER created successfully."
        USER_CHECK_RESULT=$NEW_USER
    else
        echo "User creation skipped. Exiting script."
        exit 1
    fi
fi

# Proceed with granting permissions
echo "User(s) with '_dre_readonly' found: $USER_CHECK_RESULT. Continuing with granting permissions..."

# Define and execute queries
QUERIES=( 
    "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
    "
    CREATE OR REPLACE FUNCTION get_sa()
    RETURNS SETOF pg_stat_activity
    LANGUAGE sql
    AS \$\$
        SELECT * FROM pg_catalog.pg_stat_activity;
    \$\$
    VOLATILE
    SECURITY DEFINER;

    CREATE OR REPLACE VIEW pg_stat_activity_allusers AS SELECT * FROM get_sa();
    GRANT SELECT ON pg_stat_activity_allusers TO public;
    GRANT EXECUTE ON FUNCTION get_sa() TO public;
    "
    "
    CREATE OR REPLACE FUNCTION get_querystats()
    RETURNS SETOF pg_stat_statements
    LANGUAGE sql
    AS \$\$
        SELECT * FROM pg_stat_statements;
    \$\$
    VOLATILE
    SECURITY DEFINER;

    CREATE OR REPLACE VIEW pg_stat_statements_allusers AS SELECT * FROM get_querystats();
    GRANT SELECT ON pg_stat_statements_allusers TO public;
    GRANT EXECUTE ON FUNCTION get_querystats() TO public;
    "
    "
    GRANT SELECT ON pg_stat_activity_allusers TO $USER_CHECK_RESULT;
    GRANT EXECUTE ON FUNCTION get_sa() TO $USER_CHECK_RESULT;

    GRANT SELECT ON pg_stat_statements_allusers TO $USER_CHECK_RESULT;
    GRANT EXECUTE ON FUNCTION get_querystats() TO $USER_CHECK_RESULT;
    "
    "GRANT pg_read_all_stats TO $USER_CHECK_RESULT;"
)

# Execute each query and check for success
for QUERY in "${QUERIES[@]}"; do
    echo "Executing query: $QUERY"
    if ! $PSQL_CMD -c "$QUERY" > /dev/null 2>&1; then
        echo "Error: Failed to execute query."
        exit 1
    fi
done

# Final confirmation with user-specific info
echo "Permissions granted successfully to user: $USER_CHECK_RESULT."
echo "Script executed successfully."

