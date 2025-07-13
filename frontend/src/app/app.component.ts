import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, Router, NavigationEnd } from '@angular/router';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatListModule } from '@angular/material/list';
import { MatMenuModule } from '@angular/material/menu';
import { filter } from 'rxjs/operators';

import { AuthService } from './core/services/auth.service';
import { LoadingService } from './core/services/loading.service';
import { NotificationService } from './core/services/notification.service';
import { LoadingComponent } from './shared/components/loading/loading.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterOutlet,
    MatSidenavModule,
    MatToolbarModule,
    MatIconModule,
    MatButtonModule,
    MatListModule,
    MatMenuModule,
    LoadingComponent
  ],
  template: `
    <div class="app-container" *ngIf="authService.isAuthenticated$ | async; else loginLayout">
      <mat-sidenav-container class="sidenav-container">
        <mat-sidenav #drawer class="sidenav" fixedInViewport mode="side" opened>
          <mat-toolbar>Menu</mat-toolbar>
          <mat-nav-list>
            <a mat-list-item routerLink="/dashboard" routerLinkActive="active">
              <mat-icon matListItemIcon>dashboard</mat-icon>
              <span matListItemTitle>Dashboard</span>
            </a>
            <a mat-list-item routerLink="/services" routerLinkActive="active">
              <mat-icon matListItemIcon>cloud</mat-icon>
              <span matListItemTitle>Services</span>
            </a>
            <a mat-list-item routerLink="/profile" routerLinkActive="active">
              <mat-icon matListItemIcon>person</mat-icon>
              <span matListItemTitle>Profile</span>
            </a>
            <a mat-list-item routerLink="/admin" routerLinkActive="active" *ngIf="authService.isAdmin$ | async">
              <mat-icon matListItemIcon>admin_panel_settings</mat-icon>
              <span matListItemTitle>Admin</span>
            </a>
          </mat-nav-list>
        </mat-sidenav>
        
        <mat-sidenav-content>
          <mat-toolbar color="primary">
            <button
              type="button"
              aria-label="Toggle sidenav"
              mat-icon-button
              (click)="drawer.toggle()">
              <mat-icon aria-label="Side nav toggle icon">menu</mat-icon>
            </button>
            <span>{{ title }}</span>
            <span class="spacer"></span>
            
            <button mat-button [matMenuTriggerFor]="userMenu">
              <mat-icon>account_circle</mat-icon>
              {{ (authService.currentUser$ | async)?.username }}
            </button>
            
            <mat-menu #userMenu="matMenu">
              <button mat-menu-item routerLink="/profile">
                <mat-icon>person</mat-icon>
                <span>Profile</span>
              </button>
              <button mat-menu-item (click)="logout()">
                <mat-icon>logout</mat-icon>
                <span>Logout</span>
              </button>
            </mat-menu>
          </mat-toolbar>
          
          <div class="content">
            <router-outlet></router-outlet>
          </div>
        </mat-sidenav-content>
      </mat-sidenav-container>
    </div>
    
    <ng-template #loginLayout>
      <router-outlet></router-outlet>
    </ng-template>
    
    <app-loading></app-loading>
  `,
  styles: [`
    .app-container {
      height: 100vh;
    }
    
    .sidenav-container {
      height: 100%;
    }
    
    .sidenav {
      width: 260px;
    }
    
    .sidenav .mat-toolbar {
      background: inherit;
    }
    
    .content {
      padding: 20px;
      height: calc(100vh - 64px);
      overflow: auto;
    }
    
    .spacer {
      flex: 1 1 auto;
    }
    
    .active {
      background-color: rgba(0, 0, 0, 0.04) !important;
    }
    
    @media (max-width: 768px) {
      .content {
        padding: 16px;
      }
    }
  `]
})
export class AppComponent implements OnInit {
  title = 'Nomad Services Platform';
  
  authService = inject(AuthService);
  loadingService = inject(LoadingService);
  notificationService = inject(NotificationService);
  router = inject(Router);

  ngOnInit() {
    // Update title based on route
    this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe(() => {
        this.updateTitle();
      });
  }

  logout() {
    this.authService.logout();
    this.router.navigate(['/auth/login']);
    this.notificationService.showSuccess('Logged out successfully');
  }

  private updateTitle() {
    const route = this.router.url;
    if (route.includes('/dashboard')) {
      this.title = 'Dashboard';
    } else if (route.includes('/services')) {
      this.title = 'Services';
    } else if (route.includes('/profile')) {
      this.title = 'Profile';
    } else if (route.includes('/admin')) {
      this.title = 'Administration';
    } else {
      this.title = 'Nomad Services Platform';
    }
  }
}
