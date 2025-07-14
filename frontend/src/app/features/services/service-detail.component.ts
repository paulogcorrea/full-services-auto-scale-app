import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, ActivatedRoute } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatChipsModule } from '@angular/material/chips';

import { ServicesService } from '../../core/services/services.service';
import { LoadingService } from '../../core/services/loading.service';
import { NotificationService } from '../../core/services/notification.service';

@Component({
  selector: 'app-service-detail',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatChipsModule
  ],
  template: `
    <div class="service-detail-container">
      <div *ngIf="loadingService.isLoading$ | async" class="loading-container">
        <mat-spinner></mat-spinner>
      </div>

      <div *ngIf="service && !(loadingService.isLoading$ | async)" class="service-detail">
        <div class="service-header">
          <div class="header-content">
            <h1>{{ service.name }}</h1>
            <mat-chip-set>
              <mat-chip [color]="getStatusColor(service.status)">
                {{ service.status }}
              </mat-chip>
            </mat-chip-set>
          </div>
          <div class="header-actions">
            <button mat-button routerLink="/services">
              <mat-icon>arrow_back</mat-icon>
              Back to Services
            </button>
            <button mat-raised-button color="primary" (click)="toggleService()">
              <mat-icon>{{ service.status === 'running' ? 'stop' : 'play_arrow' }}</mat-icon>
              {{ service.status === 'running' ? 'Stop' : 'Start' }}
            </button>
          </div>
        </div>

        <div class="service-content">
          <mat-card class="info-card">
            <mat-card-header>
              <mat-card-title>Service Information</mat-card-title>
            </mat-card-header>
            <mat-card-content>
              <div class="info-grid">
                <div class="info-item">
                  <span class="info-label">Description:</span>
                  <span class="info-value">{{ service.description || 'No description available' }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Created:</span>
                  <span class="info-value">{{ service.createdAt | date:'medium' }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">Updated:</span>
                  <span class="info-value">{{ service.updatedAt | date:'medium' }}</span>
                </div>
                <div class="info-item">
                  <span class="info-label">ID:</span>
                  <span class="info-value">{{ service.id }}</span>
                </div>
              </div>
            </mat-card-content>
          </mat-card>

          <mat-card class="actions-card">
            <mat-card-header>
              <mat-card-title>Actions</mat-card-title>
            </mat-card-header>
            <mat-card-content>
              <div class="actions-grid">
                <button mat-stroked-button (click)="toggleService()">
                  <mat-icon>{{ service.status === 'running' ? 'stop' : 'play_arrow' }}</mat-icon>
                  {{ service.status === 'running' ? 'Stop Service' : 'Start Service' }}
                </button>
                <button mat-stroked-button (click)="restartService()">
                  <mat-icon>refresh</mat-icon>
                  Restart Service
                </button>
                <button mat-stroked-button (click)="viewLogs()">
                  <mat-icon>description</mat-icon>
                  View Logs
                </button>
                <button mat-stroked-button (click)="viewMetrics()">
                  <mat-icon>analytics</mat-icon>
                  View Metrics
                </button>
              </div>
            </mat-card-content>
          </mat-card>
        </div>
      </div>

      <div *ngIf="!service && !(loadingService.isLoading$ | async)" class="error-state">
        <mat-icon>error</mat-icon>
        <h2>Service Not Found</h2>
        <p>The service you're looking for doesn't exist or you don't have permission to view it.</p>
        <button mat-raised-button color="primary" routerLink="/services">
          <mat-icon>arrow_back</mat-icon>
          Back to Services
        </button>
      </div>
    </div>
  `,
  styles: [`
    .service-detail-container {
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .loading-container {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 200px;
    }

    .service-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 32px;
      gap: 16px;
    }

    .header-content h1 {
      margin: 0 0 16px 0;
      color: #333;
      font-size: 2.5rem;
      font-weight: 300;
    }

    .header-actions {
      display: flex;
      gap: 16px;
      align-items: center;
    }

    .service-content {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 24px;
    }

    .info-card, .actions-card {
      height: fit-content;
    }

    .info-grid {
      display: grid;
      gap: 16px;
    }

    .info-item {
      display: grid;
      grid-template-columns: 1fr 2fr;
      gap: 16px;
      align-items: center;
      padding: 12px 0;
      border-bottom: 1px solid #eee;
    }

    .info-item:last-child {
      border-bottom: none;
    }

    .info-label {
      font-weight: 600;
      color: #666;
    }

    .info-value {
      color: #333;
      word-break: break-all;
    }

    .actions-grid {
      display: grid;
      gap: 12px;
    }

    .actions-grid button {
      justify-content: flex-start;
    }

    .error-state {
      text-align: center;
      padding: 64px 32px;
      color: #666;
    }

    .error-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
      color: #f44336;
    }

    .error-state h2 {
      margin: 0 0 16px 0;
      color: #333;
    }

    .error-state p {
      margin: 0 0 24px 0;
      max-width: 400px;
      margin-left: auto;
      margin-right: auto;
    }

    @media (max-width: 768px) {
      .service-detail-container {
        padding: 16px;
      }

      .service-header {
        flex-direction: column;
        align-items: flex-start;
      }

      .header-actions {
        width: 100%;
        justify-content: space-between;
      }

      .service-content {
        grid-template-columns: 1fr;
        gap: 16px;
      }

      .info-item {
        grid-template-columns: 1fr;
        gap: 4px;
      }
    }
  `]
})
export class ServiceDetailComponent implements OnInit {
  service: any = null;
  serviceId: string = '';

  constructor(
    private route: ActivatedRoute,
    private servicesService: ServicesService,
    public loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit() {
    this.route.params.subscribe(params => {
      this.serviceId = params['id'];
      this.loadService();
    });
  }

  loadService() {
    this.servicesService.getService(this.serviceId).subscribe({
      next: (service) => {
        this.service = service;
      },
      error: (error) => {
        this.notificationService.error('Failed to load service details');
        console.error('Error loading service:', error);
      }
    });
  }

  toggleService() {
    const action = this.service.status === 'running' ? 'stop' : 'start';
    
    this.servicesService.toggleService(this.serviceId, action).subscribe({
      next: () => {
        this.notificationService.success(`Service ${action}ed successfully`);
        this.loadService(); // Refresh the service details
      },
      error: (error) => {
        this.notificationService.error(`Failed to ${action} service`);
        console.error(`Error ${action}ing service:`, error);
      }
    });
  }

  restartService() {
    this.servicesService.restartService(this.serviceId).subscribe({
      next: () => {
        this.notificationService.success('Service restarted successfully');
        this.loadService(); // Refresh the service details
      },
      error: (error) => {
        this.notificationService.error('Failed to restart service');
        console.error('Error restarting service:', error);
      }
    });
  }

  viewLogs() {
    this.notificationService.info('Service logs will be implemented soon');
  }

  viewMetrics() {
    this.notificationService.info('Service metrics will be implemented soon');
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'running':
        return 'accent';
      case 'stopped':
        return 'warn';
      default:
        return 'primary';
    }
  }
}
