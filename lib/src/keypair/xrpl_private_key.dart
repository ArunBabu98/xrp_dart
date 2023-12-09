import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/compare/compare.dart';
import 'package:xrp_dart/src/xrpl/exception/exceptions.dart';
import 'xrpl_public_key.dart';

/// Enum representing different XRP key algorithms.
enum XrpKeyAlgorithm {
  /// ed25519 algorithm with a prefix of 0xED and the curve type ed25519.
  ed25519(0xED, EllipticCurveTypes.ed25519),

  /// secp256k1 algorithm with a prefix of 0x00 and the curve type secp256k1.
  secp256k1(0x00, EllipticCurveTypes.secp256k1);

  /// Prefix value associated with the key algorithm.
  final int prefix;

  /// Elliptic curve type used by the key algorithm.
  final EllipticCurveTypes curveType;

  /// Constructor to initialize the prefix and curve type for each key algorithm.
  const XrpKeyAlgorithm(this.prefix, this.curveType);
}

class XrpKeyConst {
  static const List<int> ed255PrivateKeyPrefix = [0xed];
  static const List<int> secpPrivateKey = [0x00];
  static const int privateKeyWithPrefix = 33;
}

class _XrpSeedUtils {
  /// Derives an ED25519 key from the given seed using the SHA-512 hash function.
  ///
  /// This method takes a seed as input and applies the SHA-512 hash function to it
  /// to derive an ED25519 key. It returns the derived key as a list of integers.
  static List<int> deriveED25519(List<int> seed) {
    return QuickCrypto.sha512HashHalves(seed).$1;
  }

  /// Derives a key pair from the given seed using a multi-step process.
  ///
  /// This method takes a seed as input and performs a series of steps to derive a key pair.
  /// It then returns the derived key pair as a list of integers.
  static List<int> deriveKeyPair(List<int> seed) {
    // Obtain the order of the Secp256k1 curve generator.
    final BigInt order = Curves.generatorSecp256k1.order!;

    // Calculate the root value using the provided seed.
    final BigInt root = _getSecret(seed);

    // Generate a new public point using the Secp256k1 curve and the root value.
    final newPubPoint = Curves.generatorSecp256k1 * root;

    // Calculate the intermediate value using the new public point.
    final BigInt mid = _getSecret(newPubPoint.toBytes(), isMid: true);

    // Calculate the final key pair value by combining the root and intermediate values.
    final BigInt finalPair = (root + mid) % order;

    // Convert the final key pair value to a byte array representation with a specific length.
    return BigintUtils.toBytes(finalPair, length: BigintUtils.orderLen(order));
  }

  /// Calculates the secret value from the given data using an iterative process.
  ///
  /// This method takes the given data as input and iteratively calculates a secret value.
  /// It then returns the calculated secret as a BigInt.
  static BigInt _getSecret(List<int> data, {bool isMid = false}) {
    const int sqSize = 4;
    const int sqMax = 256 << (sqSize * 8);
    for (int rawRoot = 0; rawRoot < sqMax; rawRoot++) {
      List<int> root = List<int>.filled(sqSize, 0);
      for (int i = 0; i < sqSize; i++) {
        root[i] = (rawRoot >> (8 * (sqSize - 1 - i))) & mask8;
      }
      List<int> combine;
      if (isMid) {
        combine = List<int>.from([
          ...data,
          ...[0, 0, 0, 0],
          ...root
        ]);
      } else {
        combine = [...data, ...root];
      }
      final hash = QuickCrypto.sha512Hash(combine).sublist(0, 32);
      if (Secp256k1PrivateKeyEcdsa.isValidBytes(hash)) {
        return BigintUtils.fromBytes(hash);
      }
    }
    throw ArgumentError("error");
  }

  /// Prefix used for seed values in key pair derivation.
  static const List<int> _seedPrefix = [0x21];

  /// Prefix used for ED25519 seed values in key pair derivation.
  static const List<int> _ed25519SeedPrefix = [0x01, 0xE1, 0x4B];

  /// Length constants for various XRPL components
  static const int seedLength = 16;

  /// Mapping of crypto algorithms to corresponding address prefixes
  static const Map<XrpKeyAlgorithm, List<List<int>>> _algorithmSeedPrefix = {
    XrpKeyAlgorithm.ed25519: [_ed25519SeedPrefix, _seedPrefix],
    XrpKeyAlgorithm.secp256k1: [_seedPrefix],
  };

  /// This private method encodes a byte string with a given prefix and expected length
  /// into a Ripple address using Base58 encoding with checksum.
  static String _encode(
      List<int> bytestring, List<int> prefix, int expectedLength) {
    /// Check if the expected length is non-zero and matches the actual byte string length.
    if (expectedLength != 0 && bytestring.length != expectedLength) {
      /// Throw an exception if the lengths do not match, indicating an unexpected payload length.
      throw const XRPLAddressCodecException(
          'unexpected_payload_length: len(bytestring) does not match expected_length. Ensure that the bytes are a bytestring.');
    }

    /// Encode the payload using Base58 encoding with a checksum and return the result.
    return Base58Encoder.checkEncode(
        [...prefix, ...bytestring], Base58Alphabets.ripple);
  }

  /// This private method decodes a Base58 encoded string with a provided prefix
  /// and returns the decoded byte string after validating the prefix.
  static List<int> _decode(String b58String, List<int> prefix) {
    /// Get the length of the prefix.
    final prefixLength = prefix.length;

    /// Decode the Base58 encoded string with a checksum.
    final decoded =
        Base58Decoder.checkDecode(b58String, Base58Alphabets.ripple);

    /// Check if the decoded bytes match the provided prefix.
    if (!bytesEqual(decoded.sublist(0, prefixLength), prefix)) {
      /// Throw an exception if the prefix does not match, indicating an incorrect prefix.
      throw const XRPLAddressCodecException('Provided prefix is incorrect');
    }

    /// Return the decoded byte string after removing the prefix.
    return decoded.sublist(prefixLength);
  }

  /// This method encodes a seed (entropy) into a Ripple address using the specified encoding type.
  static String encodeSeed(List<int> entropy, XrpKeyAlgorithm encodingType) {
    /// Check if the entropy length matches the expected seed length.
    if (entropy.length != seedLength) {
      throw const XRPLAddressCodecException(
          'Entropy must have length $seedLength');
    }

    /// Get the appropriate prefix for the specified encoding type.
    final prefix = _algorithmSeedPrefix[encodingType]![0];

    /// Encode the entropy with the prefix and return the resulting Ripple address.
    return _encode(entropy, prefix, seedLength);
  }

  /// This method decodes a Ripple address (seed) into its corresponding entropy and encoding algorithm.
  static (List<int>, XrpKeyAlgorithm) decodeSeed(String seed,
      [XrpKeyAlgorithm? algorithm]) {
    if (algorithm != null) {
      /// If a specific algorithm is provided, attempt to decode with that algorithm's prefix.
      for (final prefix in _algorithmSeedPrefix[algorithm]!) {
        try {
          final decodedResult = _decode(seed, prefix);
          return (decodedResult, algorithm);
        } catch (e) {
          /// Prefix is incorrect, continue to the next prefix.
          continue;
        }
      }
      throw const XRPLAddressCodecException(
          'Wrong algorithm for the seed type.');
    }

    /// If no specific algorithm is provided, try all possible algorithms.
    for (final algorithm in XrpKeyAlgorithm.values) {
      final prefix = _algorithmSeedPrefix[algorithm]![0];
      try {
        final decodedResult = _decode(seed, prefix);
        return (decodedResult, algorithm);
      } catch (e) {
        /// Prefix is incorrect, continue to the next algorithm.
        continue;
      }
    }
    throw const XRPLAddressCodecException(
        'Invalid seed; could not determine encoding algorithm');
  }
}

class XRPPrivateKey {
  XRPPrivateKey._(this._privateKey, this.algorithm);

  final IPrivateKey _privateKey;

  /// Factory constructor for generating a random XRP private key.
  /// [algorithm] specifies the cryptographic algorithm, with ED25519 being the default.
  factory XRPPrivateKey.random(
      {XrpKeyAlgorithm algorithm = XrpKeyAlgorithm.ed25519}) {
    /// Generate 16 random bytes as entropy
    final rand = QuickCrypto.generateRandom(16);

    /// Create an XRP private key from the generated entropy
    return XRPPrivateKey.fromEntropy(BytesUtils.toHexString(rand),
        algorithm: algorithm);
  }

  /// Factory constructor for creating an XRP private key from entropy.
  ///
  /// [entropy] is the entropy for generating the private key.
  /// [algorithm] specifies the cryptographic algorithm, with ED25519 being the default.
  factory XRPPrivateKey.fromEntropy(String entropy,
      {XrpKeyAlgorithm algorithm = XrpKeyAlgorithm.ed25519}) {
    final entropyBytes = BytesUtils.fromHexString(entropy);

    /// Encode the seed using XRPAddressUtilities
    _XrpSeedUtils.encodeSeed(entropyBytes, algorithm);

    switch (algorithm) {
      case XrpKeyAlgorithm.secp256k1:
        final derive = _XrpSeedUtils.deriveKeyPair(entropyBytes);
        final privateKey = Secp256k1PrivateKeyEcdsa.fromBytes(derive);
        return XRPPrivateKey._(privateKey, algorithm);
      default:
        final privateBytes = _XrpSeedUtils.deriveED25519(entropyBytes);
        final prive = Ed25519PrivateKey.fromBytes(privateBytes);
        return XRPPrivateKey._(prive, algorithm);
    }
  }

  /// Factory constructor for creating an XRP private key from a seed.
  ///
  /// [seed] is the seed value for generating the private key.
  factory XRPPrivateKey.fromSeed(String seed) {
    /// Decode the seed to retrieve entropy and algorithm
    final entropy = _XrpSeedUtils.decodeSeed(seed);

    /// Create an XRPPrivateKey from the entropy and specified algorithm
    return XRPPrivateKey.fromEntropy(BytesUtils.toHexString(entropy.$1),
        algorithm: entropy.$2);
  }

  /// Factory constructor for creating an XRP private key from a hexadecimal representation.
  ///
  /// [privateKey] is the hexadecimal private key to be used for XRP transactions.
  factory XRPPrivateKey.fromHex(String privateKey) {
    List<int> bytes = BytesUtils.fromHexString(privateKey);
    return XRPPrivateKey.fromBytes(bytes);
  }

  /// Factory constructor for creating an XRP private key from a byte representation.
  ///
  /// [keyBytes] is the byte representation of the private key.
  /// [algorithm] is the cryptographic algorithm used for the private key.
  factory XRPPrivateKey.fromBytes(List<int> keyBytes,
      {XrpKeyAlgorithm? algorithm}) {
    if (keyBytes.length == XrpKeyConst.privateKeyWithPrefix) {
      final keyPrefix = keyBytes.sublist(0, 1);
      if (bytesEqual(keyPrefix, XrpKeyConst.secpPrivateKey)) {
        keyBytes = keyBytes.sublist(1);
        algorithm ??= XrpKeyAlgorithm.secp256k1;
      } else if (bytesEqual(keyPrefix, XrpKeyConst.ed255PrivateKeyPrefix)) {
        algorithm ??= XrpKeyAlgorithm.ed25519;
      }
    }

    algorithm ??= _findAlgorithm(keyBytes);
    final privateKey = _toPrivateKey(keyBytes, algorithm);
    return XRPPrivateKey._(privateKey, algorithm);
  }

  /// Finds the XRP key algorithm based on the given key bytes.
  ///
  /// This method takes the key bytes as input and determines the XRP key algorithm
  /// based on the validity of the key bytes for different algorithms.
  static XrpKeyAlgorithm _findAlgorithm(List<int> keyBytes) {
    if (Secp256k1PrivateKeyEcdsa.isValidBytes(keyBytes)) {
      return XrpKeyAlgorithm.secp256k1;
    } else if (Ed25519PrivateKey.isValidBytes(keyBytes)) {
      return XrpKeyAlgorithm.ed25519;
    }
    throw ArgumentError("invalid private key");
  }

  /// Converts the given [keyBytes] to an instance of IPrivateKey based on the provided XRP key [algorithm].
  ///
  /// This method takes the [keyBytes] and the XRP key [algorithm] as input and attempts
  /// to convert the [keyBytes] to an instance of IPrivateKey. It handles the conversion logic
  /// based on the provided [algorithm] and returns the resulting private key.
  ///
  /// [keyBytes] The byte representation of the private key.
  /// [algorithm] The XRP key algorithm associated with the key.
  /// returns An instance of IPrivateKey representing the private key.
  static IPrivateKey _toPrivateKey(
      List<int> keyBytes, XrpKeyAlgorithm algorithm) {
    try {
      if (keyBytes.length == Ed25519KeysConst.privKeyByteLen + 1) {
        keyBytes = keyBytes.sublist(1);
      }
      return IPrivateKey.fromBytes(keyBytes, algorithm.curveType);
    } catch (e) {
      throw ArgumentError("Invalid private key");
    }
  }

  /// The XRP key algorithm associated with the private key.
  final XrpKeyAlgorithm algorithm;

  /// Signs the given [message] using the private key and returns the signature as a hexadecimal string.
  ///
  /// [message] is the message to be signed.
  String sign(String message) {
    final signer = XrpSigner.fromKeyBytes(toBytes(), algorithm.curveType);
    final sign = signer.sign(BytesUtils.fromHexString(message));
    return BytesUtils.toHexString(sign);
  }

  /// Returns the private key as a bytes.
  List<int> toBytes() {
    return _privateKey.raw;
  }

  /// Returns the private key as a hexadecimal string with the appropriate prefix based on the algorithm.
  String toHex() {
    String toString = BytesUtils.toHexString(toBytes(), false);
    if (toString.length < 64) {
      toString = toString.padLeft(64, '0');
    }
    switch (algorithm) {
      case XrpKeyAlgorithm.ed25519:
        return "ED$toString";
      default:
        return "00$toString";
    }
  }

  /// Gets the public key associated with this private key.
  XRPPublicKey getPublic() {
    return XRPPublicKey.fromBytes(_privateKey.publicKey.compressed,
        algorithm: algorithm);
  }
}