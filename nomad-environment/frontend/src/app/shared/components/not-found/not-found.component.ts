import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';

@Component({
  selector: 'app-not-found',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule
  ],
  template: `
    <div class="not-found-container">
      <mat-card class="not-found-card">
        <mat-card-content>
          <div class="icon-container">
            <mat-icon class="large-icon">error_outline</mat-icon>
          </div>
          <h1>404 - Page Not Found</h1>
          <p>The page you're looking for doesn't exist or has been moved.</p>
          <div class="actions">
            <button mat-raised-button color="primary" routerLink="/dashboard">
              <mat-icon>home</mat-icon>
              Go to Dashboard
            </button>
            <button mat-button (click)="goBack()">
              <mat-icon>arrow_back</mat-icon>
              Go Back
            </button>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .not-found-container {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 60vh;
      padding: 20px;
    }

    .not-found-card {
      max-width: 500px;
      text-align: center;
      padding: 40px 20px;
    }

    .icon-container {
      margin-bottom: 20px;
    }

    .large-icon {
      font-size: 72px;
      width: 72px;
      height: 72px;
      color: #f44336;
    }

    h1 {
      margin: 20px 0;
      color: #333;
    }

    p {
      color: #666;
      margin-bottom: 30px;
      line-height: 1.5;
    }

    .actions {
      display: flex;
      gap: 16px;
      justify-content: center;
      flex-wrap: wrap;
    }

    .actions button {
      display: flex;
      align-items: center;
      gap: 8px;
    }
  `]
})
export class NotFoundComponent {
  goBack(): void {
    window.history.back();
  }
}
