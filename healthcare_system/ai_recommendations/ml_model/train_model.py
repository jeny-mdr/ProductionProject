import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import pickle
import json
import os

print("Loading dataset...")
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Load dataset
df = pd.read_csv(os.path.join(BASE_DIR, 'dataset.csv'))

print(f"Dataset shape: {df.shape}")
print(f"Columns: {df.columns.tolist()}")

# Clean column names
df.columns = df.columns.str.strip()

# Fill NaN with empty string
df = df.fillna('')

# Get all symptom columns
symptom_cols = [c for c in df.columns if c != 'Disease']
print(f"Symptom columns: {len(symptom_cols)}")

# Get all unique symptoms
all_symptoms = set()
for col in symptom_cols:
    unique_vals = df[col].str.strip().str.lower().unique()
    all_symptoms.update([s for s in unique_vals if s != ''])

all_symptoms = sorted(list(all_symptoms))
print(f"Total unique symptoms: {len(all_symptoms)}")

# Create symptom index
symptom_index = {s: i for i, s in enumerate(all_symptoms)}

# Build feature matrix
print("Building feature matrix...")
X = np.zeros((len(df), len(all_symptoms)), dtype=int)
for i, row in df.iterrows():
    for col in symptom_cols:
        symptom = row[col].strip().lower()
        if symptom and symptom in symptom_index:
            X[i][symptom_index[symptom]] = 1

# Target labels
y = df['Disease'].str.strip()
diseases = sorted(y.unique().tolist())
disease_index = {d: i for i, d in enumerate(diseases)}
y_encoded = y.map(disease_index).values

print(f"Total diseases: {len(diseases)}")

# Train/test split
X_train, X_test, y_train, y_test = train_test_split(
    X, y_encoded, test_size=0.2, random_state=42)

# Train RandomForest
print("Training RandomForest model...")
model = RandomForestClassifier(
    n_estimators=200,
    random_state=42,
    max_depth=20,
    min_samples_split=2,
)
model.fit(X_train, y_train)

# Check accuracy
y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)
print(f"Model accuracy: {accuracy * 100:.2f}%")

# Load disease descriptions
print("Loading disease descriptions...")
desc_df = pd.read_csv(
    os.path.join(BASE_DIR, 'symptom_Description.csv'))
desc_df.columns = desc_df.columns.str.strip()
desc_map = {}
for _, row in desc_df.iterrows():
    disease = row['Disease'].strip()
    description = row['Description'].strip()
    desc_map[disease] = description

# Load precautions
print("Loading precautions...")
prec_df = pd.read_csv(
    os.path.join(BASE_DIR, 'symptom_precaution.csv'))
prec_df.columns = prec_df.columns.str.strip()
prec_map = {}
for _, row in prec_df.iterrows():
    disease = row['Disease'].strip()
    precautions = [
        str(row.get('Precaution_1', '')).strip(),
        str(row.get('Precaution_2', '')).strip(),
        str(row.get('Precaution_3', '')).strip(),
        str(row.get('Precaution_4', '')).strip(),
    ]
    prec_map[disease] = [p for p in precautions if p and p != 'nan']

# Save model
print("Saving model...")
with open(os.path.join(BASE_DIR, 'disease_model.pkl'), 'wb') as f:
    pickle.dump(model, f)

# Save metadata
metadata = {
    'symptoms': all_symptoms,
    'diseases': diseases,
    'disease_index': disease_index,
    'descriptions': desc_map,
    'precautions': prec_map,
    'accuracy': round(accuracy * 100, 2),
}
with open(os.path.join(BASE_DIR, 'model_metadata.json'), 'w') as f:
    json.dump(metadata, f, indent=2)

print("=" * 50)
print(f"✅ Model saved: disease_model.pkl")
print(f"✅ Metadata saved: model_metadata.json")
print(f"✅ Accuracy: {accuracy * 100:.2f}%")
print(f"✅ Symptoms: {len(all_symptoms)}")
print(f"✅ Diseases: {len(diseases)}")
print("=" * 50)
print("Training complete!")