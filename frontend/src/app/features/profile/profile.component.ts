import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import { AuthService } from '../../core/services/auth.service';
import { LoadingService } from '../../core/services/loading.service';
import { NotificationService } from '../../core/services/notification.service';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatCardModule,
    MatInputModule,
    MatButtonModule,
    MatFormFieldModule,
    MatProgressSpinnerModule
  ],
  template: `
    <div class="profile-container">
      <h1>Profile Settings</h1>
      
      <mat-card>
        <mat-card-header>
          <mat-card-title>Update Profile</mat-card-title>
          <mat-card-subtitle>Manage your account information</mat-card-subtitle>
        </mat-card-header>
        
        <mat-card-content>
          <form [formGroup]="profileForm" (ngSubmit)="onSubmit()">
            <mat-form-field appearance="outline" class="full-width">
              <mat-label>First Name</mat-label>
              <input matInput formControlName="firstName" placeholder="Enter your first name">
              <mat-error *ngIf="profileForm.get('firstName')?.hasError('required')">
                First name is required
              </mat-error>
            </mat-form-field>

            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Last Name</mat-label>
              <input matInput formControlName="lastName" placeholder="Enter your last name">
              <mat-error *ngIf="profileForm.get('lastName')?.hasError('required')">
                Last name is required
              </mat-error>
            </mat-form-field>

            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Email</mat-label>
              <input matInput formControlName="email" placeholder="Enter your email address">
              <mat-error *ngIf="profileForm.get('email')?.hasError('required')">
                Email is required
              </mat-error>
              <mat-error *ngIf="profileForm.get('email')?.hasError('email')">
                Please enter a valid email address
              </mat-error>
            </mat-form-field>

            <button 
              mat-raised-button 
              color="primary" 
              type="submit" 
              class="submit-button"
              [disabled]="profileForm.invalid || (loadingService.isLoading$ | async)">
              <mat-spinner *ngIf="loadingService.isLoading$ | async" diameter="20"></mat-spinner>
              <span *ngIf="!(loadingService.isLoading$ | async)">Update Profile</span>
            </button>
          </form>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .profile-container {
      padding: 24px;
      max-width: 600px;
      margin: 0 auto;
    }

    .profile-container h1 {
      margin: 0 0 32px 0;
      color: #333;
      font-size: 2.5rem;
      font-weight: 300;
    }

    .full-width {
      width: 100%;
      margin-bottom: 16px;
    }

    .submit-button {
      height: 48px;
      margin-top: 16px;
    }

    mat-spinner {
      margin-right: 8px;
    }

    @media (max-width: 768px) {
      .profile-container {
        padding: 16px;
      }
    }
  `]
})
export class ProfileComponent implements OnInit {
  profileForm: FormGroup;
  currentUser: any = null;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    public loadingService: LoadingService,
    private notificationService: NotificationService
  ) {
    this.profileForm = this.fb.group({
      firstName: ['', [Validators.required]],
      lastName: ['', [Validators.required]],
      email: ['', [Validators.required, Validators.email]]
    });
  }

  ngOnInit() {
    this.authService.currentUser$.subscribe(user => {
      if (user) {
        this.currentUser = user;
        this.profileForm.patchValue({
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email
        });
      }
    });
  }

  onSubmit() {
    if (this.profileForm.valid) {
      const formValue = this.profileForm.value;
      
      this.authService.updateProfile(formValue).subscribe({
        next: (response) => {
          this.notificationService.success('Profile updated successfully');
        },
        error: (error) => {
          this.notificationService.error(error.message || 'Failed to update profile');
        }
      });
    }
  }
}
