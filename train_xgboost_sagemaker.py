import argparse
import joblib
import os
import pandas as pd
import numpy as np
from sklearn.metrics import accuracy_score
import xgboost as xgb

def model_fn(model_dir):
    """Load the model from the model_dir. This is the same model that is saved at the end of the training script."""
    model = joblib.load(os.path.join(model_dir, "model.joblib"))
    return model

def train():
    parser = argparse.ArgumentParser()
    
    # Hyperparameters
    parser.add_argument('--max_depth', type=int, default=3)
    parser.add_argument('--eta', type=float, default=0.1)
    parser.add_argument('--num_round', type=int, default=100)
    
    # SageMaker specific arguments
    parser.add_argument('--model_dir', type=str, default=os.environ.get('SM_MODEL_DIR'))
    parser.add_argument('--train', type=str, default=os.environ.get('SM_CHANNEL_TRAIN'))
    parser.add_argument('--validation', type=str, default=os.environ.get('SM_CHANNEL_VALIDATION'))
    
    args = parser.parse_args()
    
    # Load training data
    train_data = np.load(os.path.join(args.train, 'train_data.npy'))
    train_labels = np.load(os.path.join(args.train, 'train_labels.npy'))
    
    # Load validation data
    val_data = np.load(os.path.join(args.validation, 'test_data.npy'))
    val_labels = np.load(os.path.join(args.validation, 'test_labels.npy'))
    
    # Reshape data for XGBoost (flatten images)
    train_data = train_data.reshape(train_data.shape[0], -1)
    val_data = val_data.reshape(val_data.shape[0], -1)
    
    # Create DMatrix for XGBoost
    dtrain = xgb.DMatrix(train_data, label=train_labels)
    dval = xgb.DMatrix(val_data, label=val_labels)
    
    # Set up parameters
    params = {
        'max_depth': args.max_depth,
        'eta': args.eta,
        'objective': 'multi:softprob',
        'num_class': 10,
        'eval_metric': 'mlogloss'
    }
    
    # Train the model
    evals = [(dtrain, 'train'), (dval, 'validation')]
    model = xgb.train(
        params=params,
        dtrain=dtrain,
        num_boost_round=args.num_round,
        evals=evals,
        verbose_eval=True
    )
    
    # Make predictions on validation set
    val_pred = model.predict(dval)
    val_pred_labels = np.argmax(val_pred, axis=1)
    accuracy = accuracy_score(val_labels, val_pred_labels)
    
    print(f"Validation accuracy: {accuracy}")
    
    # Save the model
    model.save_model(os.path.join(args.model_dir, 'model.json'))
    
    # Also save as joblib for compatibility
    import joblib
    joblib.dump(model, os.path.join(args.model_dir, 'model.joblib'))

if __name__ == '__main__':
    train()
