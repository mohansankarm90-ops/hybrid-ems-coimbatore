 import numpy as np
import pandas as pd
from xgboost import XGBRegressor
from sklearn.model_selection import KFold
from sklearn.metrics import r2_score, mean_squared_error

data = pd.read_csv(r'C:\Users\mohan\Downloads\surrogate_data.csv', header=None)
X = data.iloc[:, :5].values
Y = data.iloc[:, 5].values

model = XGBRegressor(n_estimators=200, max_depth=6, learning_rate=0.05,
                     subsample=0.8, random_state=42)

kf = KFold(n_splits=5, shuffle=True, random_state=42)
r2_scores, rmse_scores = [], []

for train_idx, test_idx in kf.split(X):
    X_train, X_test = X[train_idx], X[test_idx]
    y_train, y_test = Y[train_idx], Y[test_idx]
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    r2_scores.append(r2_score(y_test, y_pred))
    rmse_scores.append(np.sqrt(mean_squared_error(y_test, y_pred)))

print(f"5-Fold CV R2:   {np.mean(r2_scores):.4f} +/- {np.std(r2_scores):.4f}")
print(f"5-Fold CV RMSE: {np.mean(rmse_scores):.4f} +/- {np.std(rmse_scores):.4f} $/kWh")
print(f"Per-fold R2:   {[round(x,4) for x in r2_scores]}")
print(f"Per-fold RMSE: {[round(x,4) for x in rmse_scores]}")