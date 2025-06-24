#!/bin/bash
set -ex

# Update system
sudo dnf update -y

# Install Java 17 (Required for Jenkins)
sudo dnf install -y java-17-amazon-corretto-devel
javac --version

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install Docker
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins
sudo chmod 666 /var/run/docker.sock

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/

# Install Maven 3.6.3
MAVEN_VERSION=3.8.4
MAVEN_TAR=apache-maven-$MAVEN_VERSION-bin.tar.gz
cd /tmp
wget https://archive.apache.org/dist/maven/maven-3/3.8.4/binaries/$MAVEN_TAR
sudo tar -xvzf $MAVEN_TAR -C /opt
sudo ln -s /opt/apache-maven-$MAVEN_VERSION /opt/maven

# Set Maven environment variables
echo "export M2_HOME=/opt/maven" >> ~/.bash_profile
echo "export PATH=\$M2_HOME/bin:\$PATH" >> ~/.bash_profile
source ~/.bash_profile

# Verify Maven Installation
mvn -version

# Install Node.js 18 from NodeSource
echo "Installing Node.js 18..."
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs

# Verify Node.js installation
echo "Verifying Node.js installation..."
node -v

# Verify NPX installation
echo "Verifying NPX installation..."
npx -v

# Install MySQL Client CLI from MySQL official repository
echo "Installing MySQL Client..."
sudo dnf install mariadb105

# Verify MySQL Client installation
echo "Verifying MySQL Client installation..."
mysql --version || echo "MySQL Client installation failed!"

# Install GIT
echo "Installing GIT ..."
sudo dnf install git -y

# Verify GIT installation
echo "Verifying GIT installation..."
git --version

# Install Dependency-Check (SCA Scanning Tool)
echo "Installing OWASP Dependency-Check..."
VERSION="12.1.0"
$ curl -Ls "https://github.com/jeremylong/DependencyCheck/releases/download/v$VERSION/dependency-check-$VERSION-release.zip" --output dependency-check.zip
sudo unzip ./dependency-check.zip
sudo mv dependency-check /opt/

# Pulling owasp zap latest image from docker hub 
docker pull zaproxy/zap-stable

# Install SQLMap
git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git
cd sqlmap
chmod +x sqlmap.py

# Install XSStrike
sudo yum install python3-pip -y
git clone https://github.com/s0md3v/XSStrike.git
cd XSStrike
pip3 install -r requirements.txt
chmod +x xsstrike.py

# Start Minikube (Runs as ec2-user)
sudo -u ec2-user minikube start --driver=docker

# Display Jenkins Admin Password
echo "Jenkins setup complete. Use the following command to get the initial admin password:"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"

echo "Installation complete!"

