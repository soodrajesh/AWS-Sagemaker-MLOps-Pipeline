import sagemaker
from sagemaker.pytorch import PyTorch
from sagemaker.tuner import HyperparameterTuner

# Initialize SageMaker session and role
sagemaker_session = sagemaker.Session()
role = sagemaker.get_execution_role()
bucket = 'sagemaker-mnist-data'  # Replace with your S3 bucket
ecr_repository = 'sagemaker-pytorch-mnist'  # Replace with your ECR repository name
region = sagemaker_session.boto_region_name
image_uri = f'{sagemaker_session.boto_session.client("sts").get_caller_identity()["Account"]}.dkr.ecr.{region}.amazonaws.com/{ecr_repository}:latest'

# Define PyTorch estimator
pytorch_estimator = PyTorch(
    entry_point='train_pytorch.py',
    role=role,
    instance_count=1,
    instance_type='ml.t2.medium',  # Free Tier eligible
    framework_version='1.9.0',
    py_version='py3',
    source_dir='.',
    image_uri=image_uri,
    output_path=f's3://{bucket}/output',
    sagemaker_session=sagemaker_session
)

# Define hyperparameter ranges for tuning
hyperparameter_ranges = {
    'lr': sagemaker.tuner.ContinuousParameter(0.0001, 0.1),
    'batch-size': sagemaker.tuner.IntegerParameter(32, 256),
    'epochs': sagemaker.tuner.IntegerParameter(5, 15)
}

# Configure hyperparameter tuning job
tuner = HyperparameterTuner(
    estimator=pytorch_estimator,
    objective_metric_name='validation:accuracy',
    hyperparameter_ranges=hyperparameter_ranges,
    metric_definitions=[{'Name': 'validation:accuracy', 'Regex': 'validation-accuracy: ([0-9.]+)'}],
    max_jobs=3,  # Reduced for Free Tier
    max_parallel_jobs=1  # Reduced for Free Tier
)

# Start training job
pytorch_estimator.fit({'training': f's3://{bucket}/mnist'})

# Start hyperparameter tuning job
tuner.fit({'training': f's3://{bucket}/mnist'})