import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule
  ],
  template: `
    <div class="admin-container">
      <h1>Admin Panel</h1>
      
      <div class="admin-grid">
        <mat-card class="admin-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>people</mat-icon>
              User Management
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <p>Manage user accounts, roles, and permissions</p>
          </mat-card-content>
          <mat-card-actions>
            <button mat-button>
              <mat-icon>settings</mat-icon>
              Manage Users
            </button>
          </mat-card-actions>
        </mat-card>

        <mat-card class="admin-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>assessment</mat-icon>
              System Analytics
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <p>View system performance and usage statistics</p>
          </mat-card-content>
          <mat-card-actions>
            <button mat-button>
              <mat-icon>analytics</mat-icon>
              View Analytics
            </button>
          </mat-card-actions>
        </mat-card>

        <mat-card class="admin-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>settings</mat-icon>
              System Settings
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <p>Configure system-wide settings and preferences</p>
          </mat-card-content>
          <mat-card-actions>
            <button mat-button>
              <mat-icon>tune</mat-icon>
              Configure
            </button>
          </mat-card-actions>
        </mat-card>
      </div>
    </div>
  `,
  styles: [`
    .admin-container {
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .admin-container h1 {
      margin: 0 0 32px 0;
      color: #333;
      font-size: 2.5rem;
      font-weight: 300;
    }

    .admin-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 24px;
    }

    .admin-card {
      transition: transform 0.2s ease-in-out;
    }

    .admin-card:hover {
      transform: translateY(-2px);
    }

    .admin-card mat-card-title {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .admin-card mat-card-title mat-icon {
      color: #3f51b5;
    }

    @media (max-width: 768px) {
      .admin-container {
        padding: 16px;
      }

      .admin-grid {
        grid-template-columns: 1fr;
        gap: 16px;
      }
    }
  `]
})
export class AdminComponent {
  constructor() {}
}
