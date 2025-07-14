import { Routes } from '@angular/router';

export const servicesRoutes: Routes = [
  {
    path: '',
    loadComponent: () => import('./services-list.component').then(m => m.ServicesListComponent)
  },
  {
    path: ':id',
    loadComponent: () => import('./service-detail.component').then(m => m.ServiceDetailComponent)
  }
];
