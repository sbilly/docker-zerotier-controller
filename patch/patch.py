#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import json
import time
from datetime import datetime

# Check patch allow variable
if os.environ.get('PATCH_ALLOW', '0') != '1':
    print("PATCH: Nothing to do")
    exit()

# Load data from planets.json
# @pFile, location of planets.json
def loadPlanets(pFile):
    with open(pFile, 'r') as f:
        data = json.load(f)
    f.close()
    return data["planets"]


# Find string in lines
def findString(lines, s):
    i = 0
    s = s.strip()
    for line in lines:
        i = i + 1
        l = line.strip()
        if l[:len(s)] == s:
            return i


# Modify mkworld.cpp of ZeroTierOne
# @mFile, location of mkworld.cpp
# @pFile, location of planets.json
def modifyMKWORLD(mFile, pFile):
    with open(mFile, 'r') as file:
        lines = file.read().splitlines()
    file.close()

    roots = loadPlanets(pFile)

    worldStartLineNum = findString(lines, "// EDIT BELOW HERE")
    worldEndLineNum = findString(lines, "// END WORLD DEFINITION")

    planets = []
    for p in roots:
        planets.append("")
        planets.append("	// {}".format(p["Location"]))
        planets.append("	roots.push_back(World::Root());")
        planets.append(
            "	roots.back().identity = Identity(\"{}\");".format(p["Identity"]))
        for ep in p["Endpoints"]:
            planets.append(
                "	roots.back().stableEndpoints.push_back(InetAddress(\"{}\"));".format(ep))

    ts = int(round(time.time() * 1000))
    fileContent = []
    fileContent.extend(lines[0:worldStartLineNum + 4])
    fileContent.append(
        "	const uint64_t ts = {}ULL; // {}".format(
            ts, datetime.utcfromtimestamp(int(ts/1000)).strftime('%Y-%m-%d %H:%M:%S'))
    )
    fileContent.extend(planets)
    fileContent.extend(lines[worldEndLineNum - 2:])

    with open(mFile, 'w') as file:
        for l in fileContent:
            file.write(l+"\n")
    file.close()


# Build mkworld
# @mFile, location of mkworld.cpp
# @wFile, location of world.c
def buildMKWORLD(mFile, wFile):
    os.system(
        "cd {} && g++ -I../../ -o mkworld ../../node/C25519.cpp ../../node/Salsa20.cpp ../../node/SHA512.cpp ../../node/Identity.cpp ../../node/Utils.cpp ../../node/InetAddress.cpp ../../osdep/OSUtils.cpp mkworld.cpp -std=c++11 -w".format(os.path.dirname(mFile)))
    os.system(
        "cd {} && {} > {}".format(os.path.dirname(mFile), os.path.join(os.path.dirname(mFile), "mkworld"), os.path.join(os.path.dirname(wFile), "world.c")))


# Modify node/Topology.cpp
# @tFile, location of Topology.cpp
# @wFile, location of world.c
def modifyTOPOLOGY(tFile, wFile):
    with open(tFile, 'r') as file:
        lines = file.read().splitlines()
    file.close()

    with open(wFile, 'r') as worldFile:
        world = worldFile.read().splitlines()
    worldFile.close()

    worldStartLineNum = findString(
        lines, "#define ZT_DEFAULT_WORLD_LENGTH ")
    worldEndLineNum = findString(
        lines, "static const unsigned char ZT_DEFAULT_WORLD[ZT_DEFAULT_WORLD_LENGTH] = ")

    fileContent = []
    fileContent.extend(lines[:worldStartLineNum - 1])
    fileContent.extend(world)
    fileContent.extend(lines[worldEndLineNum:])

    with open(tFile, 'w') as file:
        for l in fileContent:
            file.write(l+"\n")
    file.close()


# Patch controller/PostgreSQL.cpp
# @pgFile, location of PostgreSQL.cpp
def patchPOSTGRESQL(pgFile, patchFile):
    os.system(
        "cd {}/.. && patch -p 0 < {}".format(os.path.dirname(pgFile), os.path.abspath(patchFile)))


def main():
    mFile = os.path.abspath("./ZeroTierOne/attic/world/mkworld.cpp")
    tFile = os.path.abspath("./ZeroTierOne/node/Topology.cpp")
    pgFile = os.path.abspath("./ZeroTierOne/controller/PostgreSQL.cpp")
    pFile = os.path.abspath("./patch/planets.json")
    patchFile = os.path.abspath("./patch/PostgreSQL.cpp.patch")
    wFile = os.path.abspath("./config/world.c")

    # Modify mkworld.cpp with planets.json
    modifyMKWORLD(mFile, pFile)
    # Compile mkworld.cpp
    buildMKWORLD(mFile, wFile)
    # Modify node/Topology.cpp with world.c
    modifyTOPOLOGY(tFile, wFile)
    # Patch controller/PostgreSQL.cpp
    # patchPOSTGRESQL(pgFile, patchFile)


main()
