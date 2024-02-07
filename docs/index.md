# HPC@Azure

This repo contains Infrastructure-as-a-Code (IaaC) for deploying an HPC cluster on Azure.

The code has been developed in order to support the pre-operational phase of the [Seareport]() Project. 
We’ve extracted the core of the codebase and made it available in this repository, hoping it might serve others as well.

During this process, we’ve simplified several aspects and removed implementation specific details.
For instance, Seareport deploys [Thalassa](https://github.com/ec-jrc/Thalassa),
a web application designed for visualizing large scale sea level data on unstructured mesh data.
However, this specific application may not be useful for other projects,
so we’ve replaced this component with a placeholder, in this case, an empty Virtual Machine.


In the same spirit, the actual code that provisions the other VMs and the HPC cluster has been removed. 
What this repository offers is a straightforward way to replicate Seareport’s high-level design.
To extract value from it, you’ll need to tailor it to your specific needs.

## Objectives

The main objectives include:

- Facilitating the effortless deployment of two separate HPC instances that can be dynamically scaled according to demand.
- Utilizing the first HPC instance for the execution of a model in an “operational” mode 
    (for instance, running the model bi-daily) and for the storage and distribution of the outcomes.
- Employing the second HPC instance to aid in the ongoing refinement of the model.

It is crucial that these two HPC instances operate independently of each other.
Any “development” tasks should be conducted in a manner that does not disrupt or interfere with the operational setup.

To achieve this goal a Bicep-based IaaC (Infrastructure-as-a-Code) solution has been developed.

## Repository directory structure

There are three main directories:

- The `infra` directory contains the bicep modules that manage the creation of resources on Azure
- The `provisioning` directory contains code helpers that can be used to provision the VMs using `ansible`. 
  This directory only contains sample playbooks.
  The actual provisioning is omitted since it is application/project specific.
- The `docs` directory contains the code that generates the current document.

## Prerequisites

- [Azure cli](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
- [Azure bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) for provisioning (optional)
- python 3 for building docs
