import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:xrp_dart/src/number/number_parser.dart';
import 'package:xrp_dart/src/xrpl/bytes/serializer.dart';
import 'package:xrp_dart/src/xrpl/models/xrp_transactions.dart';

class PaymentChannelClaimFlag implements FlagsInterface {
  // Renew the payment channel.
  static const PaymentChannelClaimFlag tfRenew =
      PaymentChannelClaimFlag(0x00010000);

  // Close the payment channel.
  static const PaymentChannelClaimFlag tfClose =
      PaymentChannelClaimFlag(0x00020000);

  // The integer value associated with each flag.
  final int value;

  // Constructor for PaymentChannelClaimFlag.
  const PaymentChannelClaimFlag(this.value);

  @override
  int get id => value;
}

class PaymentChannelClaimFlagInterface {
  PaymentChannelClaimFlagInterface(
      {required this.tfClose, required this.tfRenew});
  final bool tfRenew;
  final bool tfClose;
}

/// Represents a PaymentChannelClaim <https://xrpl.org/paymentchannelclaim.html>_
/// transaction, which claims XRP from a payment channel
/// <https://xrpl.org/payment-channels.html>_, adjusts
/// channel's expiration, or both. This transaction can be used differently
/// depending on the transaction sender's role in the specified channel.
class PaymentChannelClaim extends XRPTransaction {
  ///[channel] The unique ID of the payment channel, as a 64-character hexadecimal
  /// string
  final String channel;

  /// [balance] The cumulative amount of XRP to have delivered through this channel after
  /// processing this claim
  final BigInt? balance;

  /// [amount] The cumulative amount of XRP that has been authorized to deliver by the
  /// attached claim signature
  final BigInt? amount;

  /// [signature] The signature of the claim, as hexadecimal. This signature must be
  /// verifiable for the this channel and the given public_key and amount
  /// values. May be omitted if closing the channel or if the sender of this
  /// transaction is the source address of the channel; required otherwise.
  String? signature;

  /// [publicKey] The public key that should be used to verify the attached signature. Must
  /// match the PublicKey that was provided when the channel was created.
  /// Required if signature is provided.
  final String? publicKey;

  PaymentChannelClaim(
      {required String account,
      required this.channel,
      this.balance,
      this.amount,
      this.signature,
      this.publicKey,
      List<XRPLMemo>? memos = const [],
      String signingPubKey = "",
      int? ticketSequance,
      BigInt? fee,
      int? lastLedgerSequence,
      int? sequence,
      List<XRPLSigners>? signers,
      dynamic flags,
      int? sourceTag,
      List<String> multiSigSigners = const []})
      : super(
            account: account,
            fee: fee,
            lastLedgerSequence: lastLedgerSequence,
            memos: memos,
            sequence: sequence,
            signers: signers,
            sourceTag: sourceTag,
            flags: flags,
            ticketSequance: ticketSequance,
            signingPubKey: signingPubKey,
            multiSigSigners: multiSigSigners,
            transactionType: XRPLTransactionType.paymentChannelClaim);

  /// Converts the object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      "channel": channel,
      "balance": balance?.toString(),
      "amount": amount?.toString(),
      "signature": signature,
      "public_key": publicKey,
      ...super.toJson()
    };
  }

  PaymentChannelClaim.fromJson(Map<String, dynamic> json)
      : amount = parseBigInt(json["amount"]),
        balance = parseBigInt(json["balance"]),
        channel = json["channel"],
        publicKey = json["public_key"],
        signature = json["signature"],
        super.json(json);

  String signForClaim() {
    List<int> prefix = BytesUtils.fromHexString("434C4D00");
    final channelx = Hash256.fromValue(channel);
    final amountx = UInt64.fromValue(amount!.toInt());
    return BytesUtils.toHexString(
        [...prefix, ...channelx.toBytes(), ...amountx.toBytes()]);
  }
}
