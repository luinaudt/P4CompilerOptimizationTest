"""
Copyright 2021-present Thomas Luinaud

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

import networkx
import json
import getopt
import argparse
import sys
import os
from pathlib import Path

global options

def convertFolder(inputFolder, outputFolder, deparserName):
    if not os.path.exists(outputFolder):
        print("making output folder {}".format(outputFolder))
        os.mkdir(outputFolder)
    if not os.path.isdir(outputFolder):
        print("if input is a folder output must be a folder")
        sys.exit(1)
    for i in os.listdir(inputFolder):
        if os.path.isdir(i):
            convertFolder(os.path.join(inputFolder, i),
                          os.path.join(outputFolder,i),
                          deparserName)
        outFile = Path(os.path.join(outputFolder, i))
        outFile = str(outFile.parent.joinpath(outFile.stem + ".dot"))
        processFile(str(os.path.join(inputFolder,i)), outFile ,deparserName)
        
def getGraph(inputFile, deparserName):
    """ return networkx Graph
    """
    if Path(inputFile).suffix != ".json":
        print("{} is not a json suffix".format(inputFile))
        print("exit convertion")
        return
    print("processing {}".format(inputFile))
    with open(inputFile,'r') as f:
        deparser = json.load(f)[deparserName]
    graph = networkx.readwrite.json_graph.node_link_graph(deparser["graph"], directed=True)
    return graph, deparser["startState"], deparser["lastState"]

def processFile(inputFile, outputFile, deparserName):
    graph, startState, endState = getGraph(inputFile,deparserName)
    if options.countEdges:
        print(f"{inputFile} : edges = {networkx.number_of_edges(graph)}")
    if options.toDot:
        genDot(graph, outputFile, deparserName)
    if options.countPath:
        nbPath = sum(1 for i in networkx.all_simple_paths(graph,startState, endState))
        print(f"{inputFile} : path = {nbPath}")
    if options.countNodes:
        nbNodes = sum(1 for i in graph.nodes)
        print(f"{inputFile} : nodes = {nbNodes}")

def genDot(graph, outputFile, deparserName):
    networkx.drawing.nx_agraph.write_dot(graph, outputFile)

def convert(fileName = "a.out", outfileName= "a.dot", deparserName = "deparser"):
    if os.path.isdir(fileName):
        convertFolder(fileName, outfileName, deparserName)
    else:
        processFile(fileName, outfileName, deparserName)
    

def main(argv):
    global options
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--input", "-i", help="input file or folder of Json source files", required=True)
    parser.add_argument("--output", "-o", help="output file or folder results", required=True)
    parser.add_argument("--deparserName", help="name of the deparser", default="deparser", required=False)
    parser.add_argument("--countEdges", help="activate edges count", action="store_true", required=False)
    parser.add_argument("--countNodes", help="activate nodes count", action="store_true", required=False)
    parser.add_argument("--countPath", help="activate path count", action="store_true", required=False)
    parser.add_argument("--notToDot", dest="toDot", help="deactivate dot export", action="store_false", required=False)
    args, otherArgs = parser.parse_known_args()
    options=args
    if os.path.exists(args.input):
        convert(args.input, args.output, args.deparserName)
    else:
        print("{} does not exists".format(args.input))
        sys.exit(1)
    

if __name__ == "__main__":
    # execute only if run as a script
    main(sys.argv)
    exit()
