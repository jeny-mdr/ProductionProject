from django.db import models


class Symptom(models.Model):
    name = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return self.name


class Disease(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    doctor_specialization = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class SymptomDisease(models.Model):
    symptom = models.ForeignKey(Symptom, on_delete=models.CASCADE)
    disease = models.ForeignKey(Disease, on_delete=models.CASCADE, related_name='symptom_links')

    class Meta:
        unique_together = ('symptom', 'disease')

    def __str__(self):
        return f"{self.symptom} → {self.disease}"