from django.db import models


class Symptom(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class Disease(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()

    # doctor specialization needed for this disease
    doctor_specialization = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class SymptomDisease(models.Model):
    symptom = models.ForeignKey(Symptom, on_delete=models.CASCADE)
    disease = models.ForeignKey(Disease, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.symptom} → {self.disease}"