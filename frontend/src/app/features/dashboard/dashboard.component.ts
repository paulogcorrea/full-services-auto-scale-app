import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import { AuthService } from '../../core/services/auth.service';
import { ServicesService } from '../../core/services/services.service';
import { LoadingService } from '../../core/services/loading.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule
  ],
  template: `
    <div class="dashboard-container">
      <div class="dashboard-header">
        <h1>Dashboard</h1>
        <p>Welcome back, {{ currentUser?.firstName }}!</p>
      </div>

      <div class="dashboard-grid">
        <mat-card class="dashboard-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>cloud_circle</mat-icon>
              Services
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="stat-value">{{ serviceCount }}</div>
            <div class="stat-label">Total Services</div>
          </mat-card-content>
          <mat-card-actions>
            <button mat-button routerLink="/services">
              <mat-icon>arrow_forward</mat-icon>
              View All
            </button>
          </mat-card-actions>
        </mat-card>

        <mat-card class="dashboard-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>play_circle</mat-icon>
              Running Services
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="stat-value">{{ runningServiceCount }}</div>
            <div class="stat-label">Currently Running</div>
          </mat-card-content>
          <mat-card-actions>
            <button mat-button routerLink="/services">
              <mat-icon>visibility</mat-icon>
              Monitor
            </button>
          </mat-card-actions>
        </mat-card>

        <mat-card class="dashboard-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>add_circle</mat-icon>
              Quick Actions
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <p>Deploy new services quickly</p>
          </mat-card-content>
          <mat-card-actions>
            <button mat-raised-button color="primary" routerLink="/services">
              <mat-icon>add</mat-icon>
              Create Service
            </button>
          </mat-card-actions>
        </mat-card>

        <mat-card class="dashboard-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>account_circle</mat-icon>
              Profile
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <p>Manage your account settings</p>
          </mat-card-content>
          <mat-card-actions>
            <button mat-button routerLink="/profile">
              <mat-icon>settings</mat-icon>
              Settings
            </button>
          </mat-card-actions>
        </mat-card>
      </div>

      <div class="recent-activity" *ngIf="recentServices.length > 0">
        <h2>Recent Services</h2>
        <div class="recent-services">
          <mat-card *ngFor="let service of recentServices" class="service-card">
            <mat-card-header>
              <mat-card-title>{{ service.name }}</mat-card-title>
              <mat-card-subtitle>{{ service.status }}</mat-card-subtitle>
            </mat-card-header>
            <mat-card-content>
              <p>{{ service.description }}</p>
            </mat-card-content>
            <mat-card-actions>
              <button mat-button [routerLink]="['/services', service.id]">
                View Details
              </button>
            </mat-card-actions>
          </mat-card>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .dashboard-container {
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .dashboard-header {
      margin-bottom: 32px;
    }

    .dashboard-header h1 {
      margin: 0;
      color: #333;
      font-size: 2.5rem;
      font-weight: 300;
    }

    .dashboard-header p {
      margin: 8px 0 0 0;
      color: #666;
      font-size: 1.1rem;
    }

    .dashboard-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 24px;
      margin-bottom: 32px;
    }

    .dashboard-card {
      min-height: 200px;
      transition: transform 0.2s ease-in-out;
    }

    .dashboard-card:hover {
      transform: translateY(-2px);
    }

    .dashboard-card mat-card-header {
      padding-bottom: 16px;
    }

    .dashboard-card mat-card-title {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .dashboard-card mat-card-title mat-icon {
      color: #3f51b5;
    }

    .stat-value {
      font-size: 2.5rem;
      font-weight: 600;
      color: #3f51b5;
      margin-bottom: 8px;
    }

    .stat-label {
      color: #666;
      font-size: 0.9rem;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .recent-activity {
      margin-top: 32px;
    }

    .recent-activity h2 {
      color: #333;
      margin-bottom: 16px;
    }

    .recent-services {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
      gap: 16px;
    }

    .service-card {
      transition: transform 0.2s ease-in-out;
    }

    .service-card:hover {
      transform: translateY(-1px);
    }

    @media (max-width: 768px) {
      .dashboard-container {
        padding: 16px;
      }

      .dashboard-grid {
        grid-template-columns: 1fr;
        gap: 16px;
      }

      .recent-services {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class DashboardComponent implements OnInit {
  currentUser: any = null;
  serviceCount = 0;
  runningServiceCount = 0;
  recentServices: any[] = [];

  constructor(
    private authService: AuthService,
    private servicesService: ServicesService,
    public loadingService: LoadingService
  ) {}

  ngOnInit() {
    this.loadDashboardData();
  }

  loadDashboardData() {
    // Load current user
    this.authService.currentUser$.subscribe(user => {
      this.currentUser = user;
    });

    // Load services data
    this.servicesService.getServices().subscribe({
      next: (response) => {
        this.serviceCount = response.total || 0;
        this.runningServiceCount = response.services?.filter((s: any) => s.status === 'running').length || 0;
        this.recentServices = response.services?.slice(0, 3) || [];
      },
      error: (error) => {
        console.error('Error loading dashboard data:', error);
      }
    });
  }
}
