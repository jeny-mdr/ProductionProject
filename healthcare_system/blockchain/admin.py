from django.contrib import admin
from .models import BlockchainRecord

@admin.register(BlockchainRecord)
class BlockchainRecordAdmin(admin.ModelAdmin):
    list_display  = ['id', 'record_type', 'doctor',
                     'patient', 'created_at', 'block_hash']
    list_filter   = ['record_type']
    search_fields = ['doctor__username', 'patient__username']
    readonly_fields = ['data_hash', 'previous_hash',
                       'block_hash', 'created_at']