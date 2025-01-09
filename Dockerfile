# Using terraform latest official image
FROM harshicorp/terraform:latest

WORKDIR /workspace

COPY . .

CMD ["terraform", "apply", "-auto-approve"]
