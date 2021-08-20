import subprocess


with open("hfixes_all.txt") as f:
    lines = f.readlines()
    for line in lines:
        if "x64" in line and line[0] != ';':
            a, b = line.split(" ")
            # print(["wget", "-O", a, b.strip()])
            subprocess.run(["wget", "-O", a, b.strip()])

with open("ie11_all.txt") as f:
    lines = f.readlines()
    for line in lines:
        if "x64" in line and line[0] != ';' and "en-us" in line:
            a, b = line.split(" ")
            # print(["wget", "-O", a, b.strip()])
            subprocess.run(["wget", "-O", a, b.strip()])

with open("net4_all.txt") as f:
    lines = f.readlines()
    for line in lines:
        # Ignore Non-English Language Packs
        if "allos-" in line:
            if "allos-enu" not in line:
                continue
        if "x64" in line and line[0] != ';':
            a, b = line.split(" ")
            # print(["wget", "-O", a, b.strip()])
            subprocess.run(["wget", "-O", a, b.strip()])

with open("dx9.txt") as f:
    lines = f.readlines()
    for line in lines:
        if "directx" in line and line[0] != ';':
            a, b = line.split(" ")
            # print(["wget", "-O", a, b.strip()])
            subprocess.run(["wget", "-O", a, b.strip()])

# ERROR 404: Not Found for these, see download.log:
# subprocess.run["cp", "../hotfixes/Windows6.1-KB2533623-x64.msu", "Windows6.1-KB2533623-x64.msu"]
# subprocess.run["cp", "../hotfixes/Windows6.1-KB917607-x64.msu", "Windows6.1-KB917607-x64.msu"]

# NVMe hotfixes:
# subprocess.run(["wget", "-O", "NVMe/Windows6.1-KB3087873-v2-x64.msu", "http://download.windowsupdate.com/d/msdownload/update/software/htfx/2015/09/windows6.1-kb3087873-v2-x64_098e3dc3e7133ba8a37b2e47260cd8cba960deb8.msu"])
# subprocess.run(["wget", "-O", "NVMe/Windows6.1-KB3087873-v2-x86.msu", "http://download.windowsupdate.com/d/msdownload/update/software/htfx/2015/09/windows6.1-kb3087873-v2-x86_6e63b2150058e51f8a601c7d09a32ba61ad3254a.msu"])
