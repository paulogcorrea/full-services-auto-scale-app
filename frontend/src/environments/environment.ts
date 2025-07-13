export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api/v1',
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
    refreshInterval: 30000, // 30 seconds
    logRefreshInterval: 5000 // 5 seconds
  }
};
