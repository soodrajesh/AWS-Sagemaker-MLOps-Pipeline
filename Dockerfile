FROM python:3.8

# Install PyTorch and basic dependencies
RUN pip install torch==1.9.0 torchvision==0.10.0 numpy

# Install SageMaker training toolkit without problematic dependencies
RUN pip install --no-deps sagemaker-training==4.6.0
RUN pip install --no-deps sagemaker-pytorch-training==2.2.0

COPY train_pytorch.py /opt/ml/code/train.py

ENV SAGEMAKER_PROGRAM='train.py'