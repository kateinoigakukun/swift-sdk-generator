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

import ArgumentParser
import SwiftSDKGenerator
import FoundationInternationalization

@main
struct GeneratorCLI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(commandName: "swift-sdk-generator")

  @Flag(help: "Delegate to Docker for copying files for the target triple.")
  var withDocker: Bool = false

  @Flag(
    help: "Experimental: avoid cleaning up toolchain and SDK directories and regenerate the SDK bundle incrementally."
  )
  var incremental: Bool = false

  @Flag(name: .shortAndLong, help: "Provide verbose logging output.")
  var verbose = false

  @Option(
    help: """
    Branch of Swift to use when downloading nightly snapshots. Specify `development` for snapshots off the `main` \
    branch of Swift open source project repositories.
    """
  )
  var swiftBranch: String? = nil

  @Option(help: "Version of Swift to supply in the bundle.")
  var swiftVersion = "5.9-RELEASE"

  @Option(help: "Version of LLD linker to supply in the bundle.")
  var lldVersion = "16.0.5"

  @Option(
    help: """
    Linux distribution to use if the target platform is Linux. Available options: `ubuntu`, `rhel`. Default is `ubuntu`.
    """,
    transform: LinuxDistribution.Name.init(nameString:)
  )
  var linuxDistributionName = LinuxDistribution.Name.ubuntu

  @Option(
    help: """
    Version of the Linux distribution used as a target platform. Available options for Ubuntu: `20.04`, \
    `22.04` (default when `--linux-distribution-name` is `ubuntu`). Available options for RHEL: `ubi9` (default when \
    `--linux-distribution-name` is `rhel`).
    """
  )
  var linuxDistributionVersion: String?

  @Option(
    help: """
    CPU architecture of the host triple of the bundle. Defaults to a triple of the machine this generator is \
    running on if unspecified. Available options: \(
      Triple.CPU.allCases.map { "`\($0.rawValue)`" }.joined(separator: ", ")
    ).
    """
  )
  var hostArch: Triple.CPU? = nil

  @Option(
    help: """
    CPU architecture of the target triple of the bundle. Same as the host triple CPU architecture if unspecified. \
    Available options: \(Triple.CPU.allCases.map { "`\($0.rawValue)`" }.joined(separator: ", ")).
    """
  )
  var targetArch: Triple.CPU? = nil

  mutating func run() async throws {
    let linuxDistributionDefaultVersion = switch self.linuxDistributionName {
    case .rhel:
      "ubi9"
    case .ubuntu:
      "22.04"
    }
    let linuxDistributionVersion = self.linuxDistributionVersion ?? linuxDistributionDefaultVersion
    let linuxDistribution = try LinuxDistribution(name: linuxDistributionName, version: linuxDistributionVersion)

    let elapsed = try await ContinuousClock().measure {
      let generator = try await SwiftSDKGenerator(
        hostCPUArchitecture: self.hostArch,
        targetCPUArchitecture: self.targetArch,
        swiftVersion: self.swiftVersion,
        swiftBranch: self.swiftBranch,
        lldVersion: self.lldVersion,
        linuxDistribution: linuxDistribution,
        shouldUseDocker: self.withDocker,
        isVerbose: self.verbose
      )
      do {
        try await generator.generateBundle(shouldGenerateFromScratch: !self.incremental)
        try await generator.shutDown()
      } catch {
        try await generator.shutDown()
        throw error
      }
    }

    print("\nTime taken for this generator run: \(elapsed.formatted()).")
  }
}

extension Triple.CPU: ExpressibleByArgument {}
