//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2022-2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SystemPackage

import class Foundation.JSONEncoder
import class Foundation.JSONDecoder

private let encoder: JSONEncoder = {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
  return encoder
}()

private let decoder: JSONDecoder = {
  let decoder = JSONDecoder()
  return decoder
}()

extension SwiftSDKGenerator {
  func generateToolsetJSON(recipe: SwiftSDKRecipe) throws -> FilePath {
    logGenerationStep("Generating toolset JSON file...")

    let toolsetJSONPath = pathsConfiguration.swiftSDKRootPath.appending("toolset.json")

    var relativeToolchainBinDir = pathsConfiguration.toolchainBinDirPath

    guard
      relativeToolchainBinDir.removePrefix(pathsConfiguration.swiftSDKRootPath)
    else {
      fatalError(
        "`toolchainBinDirPath` is at an unexpected location that prevents computing a relative path"
      )
    }

    var toolset = Toolset(rootPath: relativeToolchainBinDir.string)
    recipe.applyPlatformOptions(toolset: &toolset, targetTriple: self.targetTriple)
    try writeFile(at: toolsetJSONPath, encoder.encode(toolset))

    return toolsetJSONPath
  }

  func generateDestinationJSON(toolsetPath: FilePath, sdkDirPath: FilePath, recipe: SwiftSDKRecipe) throws {
    logGenerationStep("Generating destination JSON file...")

    let destinationJSONPath = pathsConfiguration.swiftSDKRootPath.appending("swift-sdk.json")

    var relativeToolchainBinDir = pathsConfiguration.toolchainBinDirPath
    var relativeSDKDir = sdkDirPath
    var relativeToolsetPath = toolsetPath

    guard
      relativeToolchainBinDir.removePrefix(pathsConfiguration.swiftSDKRootPath),
      relativeSDKDir.removePrefix(pathsConfiguration.swiftSDKRootPath),
      relativeToolsetPath.removePrefix(pathsConfiguration.swiftSDKRootPath)
    else {
      fatalError("""
      `toolchainBinDirPath`, `sdkDirPath`, and `toolsetPath` are at unexpected locations that prevent computing \
      relative paths
      """)
    }

    var metadata = SwiftSDKMetadataV4.TripleProperties(
      sdkRootPath: relativeSDKDir.string,
      toolsetPaths: [relativeToolsetPath.string]
    )

    recipe.applyPlatformOptions(
      metadata: &metadata,
      paths: pathsConfiguration,
      targetTriple: self.targetTriple
    )

    try writeFile(
      at: destinationJSONPath,
      encoder.encode(
        SwiftSDKMetadataV4(
          targetTriples: [
            self.targetTriple.triple: metadata,
          ]
        )
      )
    )
  }

  func generateArtifactBundleManifest(hostTriples: [Triple]?) throws {
    logGenerationStep("Generating .artifactbundle manifest file...")

    let artifactBundleManifestPath = pathsConfiguration.artifactBundlePath.appending("info.json")
    var manifest: ArtifactsArchiveMetadata
    // Read the existing manifest content if it exists
    if doesFileExist(at: artifactBundleManifestPath) {
      manifest = try decoder.decode(ArtifactsArchiveMetadata.self, from: readFile(at: artifactBundleManifestPath))
    } else {
      // Otherwise, create a new manifest
      manifest = ArtifactsArchiveMetadata(schemaVersion: "1.0", artifacts: [:])
    }

    // Warn if the manifest already contains an artifact with the same ID
    if manifest.artifacts.keys.contains(artifactID) {
      logGenerationStep(
        """
        Warning: The .artifactbundle manifest already contains an artifact with the ID \(artifactID). \
        The existing artifact will be overwritten.
        """
      )
    }

    // Add the new artifact to the manifest
    manifest.artifacts[artifactID] = ArtifactsArchiveMetadata.Artifact(
      type: .swiftSDK,
      version: self.bundleVersion,
      variants: [
        ArtifactsArchiveMetadata.Variant(
          path: FilePath(artifactID).appending(self.targetTriple.triple).string,
          supportedTriples: hostTriples.map { $0.map(\.triple) }
        ),
      ]
    )

    // Write the updated manifest back to the file
    try writeFile(at: artifactBundleManifestPath, encoder.encode(manifest))
  }
}
