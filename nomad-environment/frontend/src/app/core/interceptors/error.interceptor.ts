import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { NotificationService } from '../services/notification.service';
import { LoadingService } from '../services/loading.service';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const authService = inject(AuthService);
  const notificationService = inject(NotificationService);
  const loadingService = inject(LoadingService);

  // Show loading for non-GET requests or specific endpoints
  if (req.method !== 'GET' || req.url.includes('/logs') || req.url.includes('/metrics')) {
    loadingService.show();
  }

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      loadingService.hide();

      let errorMessage = 'An unexpected error occurred';

      if (error.error?.error) {
        errorMessage = error.error.error;
      } else if (error.message) {
        errorMessage = error.message;
      }

      switch (error.status) {
        case 0:
          errorMessage = 'Unable to connect to the server. Please check your connection.';
          break;
        case 401:
          // Unauthorized - redirect to login
          authService.logout();
          router.navigate(['/auth/login']);
          errorMessage = 'Your session has expired. Please log in again.';
          break;
        case 403:
          errorMessage = 'You do not have permission to perform this action.';
          break;
        case 404:
          errorMessage = 'The requested resource was not found.';
          break;
        case 409:
          errorMessage = error.error?.error || 'A conflict occurred. The resource may already exist.';
          break;
        case 422:
          errorMessage = error.error?.error || 'Invalid data provided.';
          break;
        case 500:
          errorMessage = 'Internal server error. Please try again later.';
          break;
        case 503:
          errorMessage = 'Service temporarily unavailable. Please try again later.';
          break;
      }

      // Don't show notification for certain endpoints that handle errors themselves
      const silentEndpoints = ['/auth/login', '/auth/refresh'];
      const shouldShowNotification = !silentEndpoints.some(endpoint => req.url.includes(endpoint));

      if (shouldShowNotification) {
        notificationService.showError(errorMessage);
      }

      return throwError(() => ({
        error: errorMessage,
        status: error.status,
        timestamp: new Date().toISOString()
      }));
    }),
    // Hide loading on successful response
    catchError((error) => {
      loadingService.hide();
      return throwError(() => error);
    })
  );
};
