#!/bin/bash

# Check if DBID and Password are provided
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
sleep 60  # Wait 1 minute to reset

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

# If no user is found, exit with a message
if [[ -z "$USER_CHECK_RESULT" ]]; then
    echo "No user found with '_dre_readonly'. Exiting script."
    exit 1
fi

# Proceed with revoking permissions
echo "User(s) with '_dre_readonly' found: $USER_CHECK_RESULT. Continuing with revoking permissions..."

# Define and execute revoke queries
QUERIES=( 
    "REVOKE SELECT ON pg_stat_activity_allusers FROM $USER_CHECK_RESULT;"
    "REVOKE EXECUTE ON FUNCTION get_sa() FROM $USER_CHECK_RESULT;"
    "REVOKE SELECT ON pg_stat_statements_allusers FROM $USER_CHECK_RESULT;"
    "REVOKE EXECUTE ON FUNCTION get_querystats() FROM $USER_CHECK_RESULT;"
    "REVOKE pg_read_all_stats TO $USER_CHECK_RESULT;"
)

# Execute each revoke query and check for success
for QUERY in "${QUERIES[@]}"; do
    echo "Executing query: $QUERY"
    if ! $PSQL_CMD -c "$QUERY" > /dev/null 2>&1; then
        echo "Error: Failed to execute query."
        exit 1
    fi
done

# Final confirmation with user-specific info
echo "Permissions successfully revoked for user: $USER_CHECK_RESULT."
echo "Script executed successfully."

