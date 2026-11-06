// The namespace is the native SDK's, so autolinking can't work out this class's package.
module.exports = {
  dependency: {
    platforms: {
      android: {
        packageImportPath: 'import cloud.holline.sdk.reactnative.HollinePackage;',
        packageInstance: 'new HollinePackage()',
      },
    },
  },
}
