import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatChipsModule } from '@angular/material/chips';

import { ServicesService } from '../../core/services/services.service';
import { LoadingService } from '../../core/services/loading.service';
import { NotificationService } from '../../core/services/notification.service';

@Component({
  selector: 'app-services-list',
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
    <div class="services-container">
      <div class="services-header">
        <h1>Services</h1>
        <button mat-raised-button color="primary" (click)="createService()">
          <mat-icon>add</mat-icon>
          Create Service
        </button>
      </div>

      <div *ngIf="loadingService.isLoading$ | async" class="loading-container">
        <mat-spinner></mat-spinner>
      </div>

      <div *ngIf="!(loadingService.isLoading$ | async)" class="services-grid">
        <mat-card *ngFor="let service of services" class="service-card">
          <mat-card-header>
            <mat-card-title>{{ service.name }}</mat-card-title>
            <mat-card-subtitle>{{ service.description }}</mat-card-subtitle>
          </mat-card-header>
          
          <mat-card-content>
            <div class="service-status">
              <mat-chip-set>
                <mat-chip [color]="getStatusColor(service.status)">
                  {{ service.status }}
                </mat-chip>
              </mat-chip-set>
            </div>
            
            <div class="service-info">
              <div class="info-item">
                <mat-icon>schedule</mat-icon>
                <span>Created: {{ service.createdAt | date:'short' }}</span>
              </div>
              <div class="info-item">
                <mat-icon>update</mat-icon>
                <span>Updated: {{ service.updatedAt | date:'short' }}</span>
              </div>
            </div>
          </mat-card-content>
          
          <mat-card-actions>
            <button mat-button [routerLink]="['/services', service.id]">
              <mat-icon>visibility</mat-icon>
              View Details
            </button>
            <button mat-button (click)="toggleService(service)">
              <mat-icon>{{ service.status === 'running' ? 'stop' : 'play_arrow' }}</mat-icon>
              {{ service.status === 'running' ? 'Stop' : 'Start' }}
            </button>
          </mat-card-actions>
        </mat-card>
      </div>

      <div *ngIf="services.length === 0 && !(loadingService.isLoading$ | async)" class="empty-state">
        <mat-icon>cloud_off</mat-icon>
        <h2>No Services Yet</h2>
        <p>Create your first service to get started with the platform.</p>
        <button mat-raised-button color="primary" (click)="createService()">
          <mat-icon>add</mat-icon>
          Create Your First Service
        </button>
      </div>
    </div>
  `,
  styles: [`
    .services-container {
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .services-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 32px;
    }

    .services-header h1 {
      margin: 0;
      color: #333;
      font-size: 2.5rem;
      font-weight: 300;
    }

    .loading-container {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 200px;
    }

    .services-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
      gap: 24px;
    }

    .service-card {
      transition: transform 0.2s ease-in-out;
      height: fit-content;
    }

    .service-card:hover {
      transform: translateY(-2px);
    }

    .service-status {
      margin-bottom: 16px;
    }

    .service-info {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .info-item {
      display: flex;
      align-items: center;
      gap: 8px;
      color: #666;
      font-size: 0.9rem;
    }

    .info-item mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    .empty-state {
      text-align: center;
      padding: 64px 32px;
      color: #666;
    }

    .empty-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
      color: #ccc;
    }

    .empty-state h2 {
      margin: 0 0 16px 0;
      color: #333;
    }

    .empty-state p {
      margin: 0 0 24px 0;
      max-width: 400px;
      margin-left: auto;
      margin-right: auto;
    }

    @media (max-width: 768px) {
      .services-container {
        padding: 16px;
      }

      .services-header {
        flex-direction: column;
        gap: 16px;
        align-items: flex-start;
      }

      .services-grid {
        grid-template-columns: 1fr;
        gap: 16px;
      }
    }
  `]
})
export class ServicesListComponent implements OnInit {
  services: any[] = [];

  constructor(
    private servicesService: ServicesService,
    public loadingService: LoadingService,
    private notificationService: NotificationService
  ) {}

  ngOnInit() {
    this.loadServices();
  }

  loadServices() {
    this.servicesService.getServices().subscribe({
      next: (response) => {
        this.services = response.services || [];
      },
      error: (error) => {
        this.notificationService.error('Failed to load services');
        console.error('Error loading services:', error);
      }
    });
  }

  createService() {
    this.notificationService.info('Service creation will be implemented soon');
  }

  toggleService(service: any) {
    const action = service.status === 'running' ? 'stop' : 'start';
    
    this.servicesService.toggleService(service.id, action).subscribe({
      next: () => {
        this.notificationService.success(`Service ${action}ed successfully`);
        this.loadServices(); // Refresh the list
      },
      error: (error) => {
        this.notificationService.error(`Failed to ${action} service`);
        console.error(`Error ${action}ing service:`, error);
      }
    });
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
