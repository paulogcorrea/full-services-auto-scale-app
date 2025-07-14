import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, BehaviorSubject, tap } from 'rxjs';
import { environment } from '@environments/environment';
import {
  Service,
  CreateServiceRequest,
  ServiceListResponse,
  ServiceLogsResponse,
  ServiceMetricsResponse,
  ServiceTemplate,
  ServiceFilter,
  ServiceDeployment
} from '../models';

@Injectable({
  providedIn: 'root'
})
export class ServicesService {
  private http = inject(HttpClient);
  private servicesSubject = new BehaviorSubject<Service[]>([]);
  
  public services$ = this.servicesSubject.asObservable();

  // Service CRUD Operations
  getServices(filter?: ServiceFilter): Observable<ServiceListResponse> {
    let params = new HttpParams();
    
    if (filter?.type) {
      params = params.set('type', filter.type);
    }
    if (filter?.status) {
      params = params.set('status', filter.status);
    }
    if (filter?.search) {
      params = params.set('search', filter.search);
    }

    return this.http.get<ServiceListResponse>(`${environment.apiUrl}/services`, { params })
      .pipe(
        tap(response => {
          this.servicesSubject.next(response.services);
        })
      );
  }

  getService(id: string): Observable<Service> {
    return this.http.get<Service>(`${environment.apiUrl}/services/${id}`);
  }

  createService(serviceData: CreateServiceRequest): Observable<Service> {
    return this.http.post<Service>(`${environment.apiUrl}/services`, serviceData)
      .pipe(
        tap(() => {
          // Refresh services list
          this.refreshServices();
        })
      );
  }

  updateService(id: string, serviceData: CreateServiceRequest): Observable<Service> {
    return this.http.put<Service>(`${environment.apiUrl}/services/${id}`, serviceData)
      .pipe(
        tap(() => {
          this.refreshServices();
        })
      );
  }

  deleteService(id: string): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${environment.apiUrl}/services/${id}`)
      .pipe(
        tap(() => {
          this.refreshServices();
        })
      );
  }

  // Service Lifecycle Operations
  startService(id: string): Observable<{ message: string; deployment: ServiceDeployment }> {
    return this.http.post<{ message: string; deployment: ServiceDeployment }>(
      `${environment.apiUrl}/services/${id}/start`, 
      {}
    ).pipe(
      tap(() => {
        this.refreshServices();
      })
    );
  }

  stopService(id: string): Observable<{ message: string }> {
    return this.http.post<{ message: string }>(`${environment.apiUrl}/services/${id}/stop`, {})
      .pipe(
        tap(() => {
          this.refreshServices();
        })
      );
  }

  restartService(id: string): Observable<{ message: string }> {
    return this.http.post<{ message: string }>(`${environment.apiUrl}/services/${id}/restart`, {})
      .pipe(
        tap(() => {
          this.refreshServices();
        })
      );
  }

  toggleService(id: string, action: 'start' | 'stop'): Observable<{ message: string; deployment?: ServiceDeployment }> {
    if (action === 'start') {
      return this.startService(id);
    } else {
      return this.stopService(id);
    }
  }

  // Service Monitoring
  getServiceLogs(id: string): Observable<ServiceLogsResponse> {
    return this.http.get<ServiceLogsResponse>(`${environment.apiUrl}/services/${id}/logs`);
  }

  getServiceMetrics(id: string): Observable<ServiceMetricsResponse> {
    return this.http.get<ServiceMetricsResponse>(`${environment.apiUrl}/services/${id}/metrics`);
  }

  // Service Templates
  getServiceTemplates(): Observable<{ templates: ServiceTemplate[]; total: number }> {
    return this.http.get<{ templates: ServiceTemplate[]; total: number }>(
      `${environment.apiUrl}/templates`
    );
  }

  getServiceTemplate(id: string): Observable<ServiceTemplate> {
    return this.http.get<ServiceTemplate>(`${environment.apiUrl}/templates/${id}`);
  }

  // Utility Methods
  refreshServices(): void {
    this.getServices().subscribe();
  }

  getServicesByType(type: string): Service[] {
    return this.servicesSubject.value.filter(service => service.type === type);
  }

  getServicesByStatus(status: string): Service[] {
    return this.servicesSubject.value.filter(service => service.status === status);
  }

  getServiceTypeIcon(type: string): string {
    const iconMap: Record<string, string> = {
      database: 'storage',
      web_server: 'language',
      message_queue: 'queue',
      monitoring: 'monitor',
      devops: 'build',
      custom: 'extension'
    };
    return iconMap[type] || 'help_outline';
  }

  getServiceTypeColor(type: string): string {
    const colorMap: Record<string, string> = {
      database: '#4caf50',
      web_server: '#2196f3',
      message_queue: '#ff9800',
      monitoring: '#9c27b0',
      devops: '#f44336',
      custom: '#607d8b'
    };
    return colorMap[type] || '#9e9e9e';
  }

  getStatusColor(status: string): string {
    const colorMap: Record<string, string> = {
      running: '#4caf50',
      stopped: '#f44336',
      pending: '#ff9800',
      error: '#e91e63'
    };
    return colorMap[status] || '#9e9e9e';
  }

  formatResourceValue(value: number, unit: string): string {
    if (unit === 'memory' || unit === 'disk') {
      if (value >= 1024) {
        return `${(value / 1024).toFixed(1)} GB`;
      }
      return `${value} MB`;
    }
    if (unit === 'cpu') {
      if (value >= 1000) {
        return `${(value / 1000).toFixed(1)} GHz`;
      }
      return `${value} MHz`;
    }
    return `${value} ${unit}`;
  }

  // Service validation
  validateServiceName(name: string): boolean {
    // Service name should be alphanumeric with hyphens/underscores
    const regex = /^[a-zA-Z0-9][a-zA-Z0-9-_]*[a-zA-Z0-9]$/;
    return regex.test(name) && name.length >= 3 && name.length <= 50;
  }

  validatePorts(ports: string): boolean {
    try {
      const portArray = ports.split(',').map(p => parseInt(p.trim()));
      return portArray.every(port => port > 0 && port <= 65535);
    } catch {
      return false;
    }
  }

  // Service configuration helpers
  createDefaultConfig(type: string): any {
    const defaults: Record<string, any> = {
      database: {
        image: 'postgres:13',
        ports: [5432],
        environment: {
          POSTGRES_USER: 'user',
          POSTGRES_PASSWORD: 'password',
          POSTGRES_DB: 'database'
        },
        resources: { cpu: 500, memory: 1024, disk: 2048 },
        nomad_job_file: 'postgresql.nomad'
      },
      web_server: {
        image: 'nginx:alpine',
        ports: [80],
        environment: {},
        resources: { cpu: 250, memory: 512, disk: 1024 },
        nomad_job_file: 'nginx.nomad'
      },
      message_queue: {
        image: 'redis:alpine',
        ports: [6379],
        environment: {},
        resources: { cpu: 250, memory: 512, disk: 1024 },
        nomad_job_file: 'redis.nomad'
      }
    };

    return defaults[type] || {
      image: '',
      ports: [8080],
      environment: {},
      resources: { cpu: 250, memory: 512, disk: 1024 },
      nomad_job_file: 'generic.nomad'
    };
  }
}
