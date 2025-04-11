require("appdynamics").profile({
    // debug: true,
    clsDisabled: true,
    maxProcessSnapshotsPerPeriod:1,
    reuseNode: true,
    reuseNodePrefix: process.env.APPDYNAMICS_AGENT_REUSE_NODE_NAME_PREFIX,
    proxyHost: process.env.APPDYNAMICS_PROXY_HOST_NAME,
    proxyPort: process.env.APPDYNAMICS_PROXY_PORT,
    logging: {
        'logfiles': [
            {
                filename: 'nodejs_agent_%N.log',
                level: 'INFO'
            }
        ]
    }
});
