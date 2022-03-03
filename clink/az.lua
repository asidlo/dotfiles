---@diagnostic disable: undefined-global
clink.argmatcher('az')({
    'account' .. clink.argmatcher()
        :addarg({
            'alias' .. clink.argmatcher()
                :addarg({
                    'create',
                    'delete',
                    'list',
                    'show',
                    'wait',
                })
                :adddescriptions(
                    { 'create', description = 'Create Alias Subscription.' },
                    { 'delete', description = 'Delete Alias.' },
                    { 'list', description = 'List Alias Subscriptions.' },
                    { 'show', description = 'Get Alias Subscription.' },
                    { 'wait', description = 'Place the CLI in a waiting state until a condition of the account alias is met.' }
                ),
            'clear',
            'create',
            'get-access-token',
            'list',
            'list-locations',
            'lock',
            'management-group',
            'set',
            'show',
            'subscription',
            'tenant',
        })
        :adddescriptions(
            { 'alias', description = 'Manage subscription alias.' },
            { 'clear', description = "Clear all subscriptions from the CLI's local cache." },
            { 'create', description = 'Create a subscription.' },
            { 'get-access-token', description = 'Get a token for utilities to access Azure.' },
            {
                'list',
                description = "Get a list of subscriptions for the logged in account. By default, only 'Enabled' subscriptions from the current cloud is shown.",
            },
            { 'list-locations', description = 'List supported regions for the current subscription.' },
            { 'lock', description = 'Manage Azure subscription level locks.' },
            { 'management-group', description = 'Manage Azure Management Groups.' },
            { 'set', description = 'Set a subscription to be the current active subscription.' },
            { 'show', description = 'Get the details of a subscription.' },
            { 'subscription', description = 'Manage subscriptions.' },
            { 'tenant', description = 'Manage tenant.' }
        ),
    'acr',
    'acs',
    'ad',
    'advisor',
    'afd',
    'ai-examples',
    'aks',
    'alias',
    'ams',
    'apim',
    'appconfig',
    'appservice',
    'arcappliance',
    'arcdata',
}):adddescriptions(
    { '-h', '--help', '-?', description = 'Show help text' },
    { 'account', description = 'Manage Azure subscription information.' },
    { 'acr', description = 'Manage private registries with Azure Container Registries.' },
    { 'acs', description = 'Manage Azure Container Services.' },
    { 'ad', description = 'Manage Azure Active Directory Graph entities needed for Role Based Access Control.' },
    { 'advisor', description = 'Manage Azure Advisor.' },
    { 'afd', description = 'Manage Azure Front Door.' },
    { 'ai-examples', description = 'Add AI powered examples to help content.' },
    { 'aks', description = 'Manage Azure Kubernetes Services.' },
    { 'alias', description = 'Manage Azure CLI Aliases.' },
    { 'ams', description = 'Manage Azure Media Services resources.' },
    { 'apim', description = 'Manage Azure API Management services.' },
    { 'appconfig', description = 'Manage App Configurations.' },
    { 'appservice', description = 'Manage App Service plans.' },
    { 'arcappliance', description = 'Commands to manage an Appliance resource.' },
    { 'arcdata', description = 'Commands for using Azure Arc-enabled data services.' }
)
