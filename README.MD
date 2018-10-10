# Status
[![Project Status: Unsupported – The project has reached a stable, usable state but the author(s) have ceased all work on it. A new maintainer may be desired.](https://www.repostatus.org/badges/latest/unsupported.svg)](https://www.repostatus.org/#unsupported)

# QRS API - Removing Unwanted Users with PowerShell

## Preamble
Ever have a situation where you attach a User Directory Connector and bring in all of the users only to realize you only needed to bring in ten users?  How do you remove the other 49,990 users you don't want referenced in the Qlik Sense Repository?

## Introduction
This PowerShell script demonstrates a method for removing unwanted users from the Qlik Sense Repository using the Qlik Sense Repository Service API.  Is it the only method?  No, definitely not.  But it's a handy way to leverage existing Windows tools to connect to Qlik Sense and use Qlik Sense Custom Properties to identify users to keep in a purge.  The benefit of the method is it automates the manual user delete process many admins probably go through today to remove users from the repository.

## Requirements and Assumptions
* Windows Powershell version 3 or above
* Qlik Sense Server (Qlik Sense Enterprise or QAP)
* Qlik Sense virtual proxy configured for header injection **[Configuration link here](https://community.qlik.com/docs/DOC-12331)**
* This document uses the Qlik Sense generated server certificate for QRS connectivity.
* This Powershell script will be run on the server Qlik Sense is installed.
* The OS used for this document is Windows 2012 R2.

## Configuration and Use

Learn more about how to use this Powershell script on **[Qlik Community](https://community.qlik.com/docs/DOC-13985)**.
