import PackageDescription

let package = Package(
    name: "Pseudoc",
    dependencies: [
        .Package(url: "https://github.com/rxwei/Parsey", majorVersion: 1)
    ]
)
