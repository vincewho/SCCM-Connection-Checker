# SCCM Connectivity Checker - Frequently Asked Questions (FAQ)

This FAQ provides answers to common questions about the SCCM Connectivity Checker PowerShell script.

## 1. What is the SCCM Connectivity Checker?

The SCCM Connectivity Checker is a PowerShell script with a simple graphical user interface (GUI). Its purpose is to help IT administrators quickly test basic network connectivity to key SCCM (System Center Configuration Manager) server roles: Management Points (MP), Distribution Points (DP), and Database Servers (DB).

## 2. Who is this tool for?

This tool is primarily for:
* SCCM administrators.
* IT support personnel troubleshooting SCCM client or server issues.
* Anyone needing to quickly verify network paths and essential ports for SCCM infrastructure.

## 3. What does it check?

The script currently performs the following checks for each specified server:

* **DNS Resolution:** Verifies that the server's hostname can be resolved to an IP address.
* **Ping Test:** Sends ICMP echo requests to see if the server is reachable on the network.
* **TCP Port Checks:**
    * **Management Point (MP):** Checks ports 80 (HTTP) and 443 (HTTPS).
    * **Distribution Point (DP):** Checks ports 80 (HTTP), 443 (HTTPS), and 445 (SMB).
    * **Database Server (DB):** Checks port 1433 (SQL Server default instance) and gives a notice for 1434 (SQL Browser UDP).

## 4. How do I use it?

1.  **Save the Script:** Save the script content as a `.ps1` file (e.g., `SCCM_Check.ps1`).
2.  **Run with PowerShell:**
    * Open PowerShell.
    * Navigate to the directory where you saved the file.
    * Run the script: `.\SCCM_Check.ps1`
    * You might need to adjust your PowerShell execution policy if scripts are disabled (e.g., `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`).
3.  **Enter Server Names:** In the GUI window, type the Fully Qualified Domain Names (FQDNs) or IP addresses of your MP, DP, and DB servers into the respective text boxes.
4.  **Run Checks:** Click the "Run Checks" button.
5.  **View Results:** The results will appear in the text area below the button, with timestamps and color-coded messages.

## 5. What are the requirements to run this script?

* **PowerShell Version:** Version 5.1 or higher.
* **.NET Framework:** The script uses Windows Forms, which is part of the .NET Framework (usually available by default on modern Windows).
* **Network Access:** The machine running the script must have network access to the SCCM servers you are testing.
* **Permissions:**
    * For basic ping and TCP port tests, standard user permissions are often sufficient.
    * If you extend the script to check WMI, services, or remote IIS, you'll need appropriate administrative permissions on the target servers.

## 6. What do the different colors in the results mean?

The script uses colors to indicate the status of each check:

* **Dark Blue:** Header messages (e.g., "--- Starting checks for MP: server.domain.com ---").
* **Dark Slate Gray:** Sub-header messages (e.g., "Performing DNS Resolution...").
* **Green:** Successful checks (e.g., "Ping server.domain.com: SUCCESS").
* **Red:** Failed checks (e.g., "Port 80 (HTTP): CLOSED or FILTERED").
* **OrangeRed:** Warnings (e.g., "No server name provided..." or for UDP port check notes).
* **Black:** General informational messages.

## 7. What if DNS resolution fails for a server?

If DNS resolution fails for a server, the script will report the failure and will **not** attempt any further checks (like ping or port tests) for that specific server. This is because subsequent network tests rely on successfully resolving the hostname to an IP address. You'll need to troubleshoot DNS issues first.

## 8. Why does the UDP port check for SQL Browser (port 1434) say "Manual check recommended"?

`Test-NetConnection` (the cmdlet used for port testing) is primarily designed for TCP connections. While it can be pointed at a UDP port, it doesn't truly test UDP connectivity in a reliable way (it sends a TCP SYN packet to a UDP port). A proper UDP test would involve sending actual UDP traffic and expecting a specific UDP response, which is more complex. Therefore, the script provides a warning for UDP ports, suggesting a manual check or using a different tool specifically designed for UDP testing if needed.

## 9. Can I add more checks to this tool?

Yes! The script is designed with a separation between the GUI logic and the connectivity checking functions (`Invoke-ServerConnectivityChecks`). You can modify the `Invoke-ServerConnectivityChecks` function to include additional tests, such as:
* WMI queries
* Service status checks
* IIS application pool status
* Content share accessibility
* SQL database connection tests

Remember to update the `Add-CheckResult` calls with appropriate messages and statuses.

## 10. What if the GUI becomes unresponsive during checks?

The current version of the script runs checks sequentially. If a server is very slow to respond or a port check times out (default 5 seconds in `Test-NetConnection`), the GUI might appear to freeze temporarily. For very extensive checks or very slow networks, future enhancements could involve running tests asynchronously using PowerShell Jobs to keep the GUI more responsive. For now, please allow some time for the checks to complete.

## 11. How can I save the results?

Currently, the script does not have a built-in "Save Log" button. However, you can easily copy the text from the results box:
1.  Click inside the results text area.
2.  Press `Ctrl+A` to select all text.
3.  Press `Ctrl+C` to copy the text.
4.  Paste the text into Notepad or any other text editor and save it.

## 12. Do I need special permissions to run this script?

* **For the current checks (DNS, Ping, TCP Port Scan):** Generally, no special administrative permissions are needed on the machine running the script, nor on the target servers, beyond what's required for basic network communication.
* **For potential future checks (WMI, remote service status, etc.):** If you extend the script to perform more in-depth checks, the account running the script will likely need administrative privileges on the target SCCM servers.

---

We hope this FAQ is helpful!
