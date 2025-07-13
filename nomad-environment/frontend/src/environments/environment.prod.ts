export const environment = {
  production: true,
  apiUrl: 'https://api.nomadservices.com/api/v1',
  appTitle: 'Nomad Services Platform',
  version: '1.0.0',
  features: {
    enableServiceTemplates: true,
    enableMetrics: true,
    enableLogs: true,
    enableNotifications: true
  },
  ui: {
    defaultPageSize: 10,
    maxPageSize: 100,
    refreshInterval: 60000, // 60 seconds
    logRefreshInterval: 10000 // 10 seconds
  }
};
