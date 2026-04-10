from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Patient, Doctor


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ['username', 'email', 'role', 'is_active']
    list_filter = ['role']
    fieldsets = UserAdmin.fieldsets + (
        ('Role', {'fields': ('role',)}),
    )


@admin.register(Doctor)
class DoctorAdmin(admin.ModelAdmin):
    list_display = ['user', 'specialization', 'hospital', 'consultation_fee', 'is_verified']
    list_filter = ['is_verified', 'specialization']
    actions = ['verify_doctors', 'unverify_doctors']

    @admin.action(description='Verify selected doctors')
    def verify_doctors(self, request, queryset):
        queryset.update(is_verified=True)

    @admin.action(description='Unverify selected doctors')
    def unverify_doctors(self, request, queryset):
        queryset.update(is_verified=False)


@admin.register(Patient)
class PatientAdmin(admin.ModelAdmin):
    list_display = ['user', 'age']