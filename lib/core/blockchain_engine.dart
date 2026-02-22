import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/contracts.dart';
import 'package:web3dart/crypto.dart';
import 'package:hex/hex.dart';

class BlockchainEngine {
  static BlockchainEngine? _instance;
  static BlockchainEngine get instance => _instance ??= BlockchainEngine._internal();
  BlockchainEngine._internal();

  // Web3 Configuration
  Web3Client? _web3client;
  Credentials? _credentials;
  EthereumAddress? _contractAddress;
  DeployedContract? _contract;
  
  // Blockchain State
  bool _isInitialized = false;
  bool _isConnected = false;
  String? _networkName;
  int? _chainId;
  String? _accountAddress;
  BigInt? _balance;
  
  // Smart Contract ABI
  static const String _contractABI = '''
    [
      {
        "anonymous": false,
        "inputs": [
          {"indexed": true, "name": "dataId", "type": "string"},
          {"indexed": true, "name": "owner", "type": "address"},
          {"indexed": false, "name": "timestamp", "type": "uint256"},
          {"indexed": false, "name": "dataHash", "type": "bytes32"}
        ],
        "name": "DataStored",
        "type": "event"
      },
      {
        "anonymous": false,
        "inputs": [
          {"indexed": true, "name": "dataId", "type": "string"},
          {"indexed": true, "name": "owner", "type": "address"},
          {"indexed": false, "name": "timestamp", "type": "uint256"}
        ],
        "name": "DataUpdated",
        "type": "event"
      },
      {
        "anonymous": false,
        "inputs": [
          {"indexed": true, "name": "dataId", "type": "string"},
          {"indexed": true, "name": "owner", "type": "address"},
          {"indexed": false, "name": "timestamp", "type": "uint256"}
        ],
        "name": "DataDeleted",
        "type": "event"
      },
      {
        "inputs": [
          {"name": "dataId", "type": "string"},
          {"name": "dataHash", "type": "bytes32"},
          {"name": "metadata", "type": "string"}
        ],
        "name": "storeData",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "dataId", "type": "string"},
          {"name": "newDataHash", "type": "bytes32"},
          {"name": "metadata", "type": "string"}
        ],
        "name": "updateData",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "dataId", "type": "string"}],
        "name": "deleteData",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "dataId", "type": "string"}],
        "name": "verifyData",
        "outputs": [
          {"name": "exists", "type": "bool"},
          {"name": "owner", "type": "address"},
          {"name": "dataHash", "type": "bytes32"},
          {"name": "timestamp", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "owner", "type": "address"}],
        "name": "getDataByOwner",
        "outputs": [{"name": "dataIds", "type": "string[]"}],
        "stateMutability": "view",
        "type": "function"
      }
    ]
  ''';

  // Local Blockchain State
  final Map<String, BlockchainRecord> _localLedger = {};
  final List<BlockchainTransaction> _transactionPool = [];
  final Map<String, BlockchainProof> _proofs = {};
  
  // Configuration
  bool _useLocalBlockchain = true;
  bool _enableMining = false;
  int _difficulty = 4;
  int _blockSize = 10;
  Duration _blockTime = Duration(seconds: 10);

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  String? get networkName => _networkName;
  int? get chainId => _chainId;
  String? get accountAddress => _accountAddress;
  BigInt? get balance => _balance;
  Map<String, BlockchainRecord> get localLedger => Map.from(_localLedger);
  List<BlockchainTransaction> get transactionPool => List.from(_transactionPool);

  /// Initialize Blockchain Engine
  Future<bool> initialize({
    String? rpcUrl,
    String? privateKey,
    String? contractAddress,
    bool useLocalBlockchain = true,
    bool enableMining = false,
  }) async {
    if (_isInitialized) return true;

    try {
      _useLocalBlockchain = useLocalBlockchain;
      _enableMining = enableMining;

      if (!_useLocalBlockchain) {
        // Initialize Web3 client
        await _initializeWeb3(rpcUrl, privateKey, contractAddress);
      } else {
        // Initialize local blockchain
        await _initializeLocalBlockchain();
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _initializeWeb3(String? rpcUrl, String? privateKey, String? contractAddress) async {
    try {
      // Connect to Ethereum network
      _web3client = Web3Client(
        rpcUrl ?? 'https://mainnet.infura.io/v3/YOUR_PROJECT_ID',
        HttpClient(),
      );

      // Set up credentials
      if (privateKey != null) {
        _credentials = EthPrivateKey.fromHex(privateKey);
        _accountAddress = _credentials!.address.hex;
      }

      // Get network info
      _networkName = await _web3client!.getNetwork();
      _chainId = await _web3client!.getChainId();

      // Get balance
      if (_accountAddress != null) {
        _balance = await _web3client!.getBalance(EthereumAddress.fromHex(_accountAddress!));
      }

      // Set up contract
      if (contractAddress != null) {
        _contractAddress = EthereumAddress.fromHex(contractAddress);
        _contract = DeployedContract(
          ContractAbi.fromJson(_contractABI, 'DataIntegrity'),
          _contractAddress!,
        );
      }

      _isConnected = true;
    } catch (e) {
      throw Exception('Failed to initialize Web3: $e');
    }
  }

  Future<void> _initializeLocalBlockchain() async {
    // Create genesis block
    final genesisBlock = BlockchainBlock(
      index: 0,
      timestamp: DateTime.now(),
      previousHash: '0' * 64,
      data: ['Genesis Block'],
      nonce: 0,
      hash: _calculateBlockHash(0, DateTime.now(), '0' * 64, ['Genesis Block'], 0),
    );

    _localLedger['genesis'] = BlockchainRecord(
      id: 'genesis',
      type: 'block',
      data: genesisBlock.toMap(),
      timestamp: genesisBlock.timestamp,
      hash: genesisBlock.hash,
      previousHash: genesisBlock.previousHash,
    );

    if (_enableMining) {
      _startMining();
    }
  }

  /// Store data on blockchain
  Future<BlockchainTransaction> storeData({
    required String dataId,
    required Map<String, dynamic> data,
    String? metadata,
  }) async {
    try {
      final dataHash = _calculateDataHash(data);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      BlockchainTransaction transaction;

      if (!_useLocalBlockchain) {
        // Store on Ethereum
        transaction = await _storeDataOnEthereum(dataId, dataHash, metadata ?? '');
      } else {
        // Store on local blockchain
        transaction = await _storeDataOnLocalBlockchain(dataId, data, dataHash, metadata);
      }

      // Add to transaction pool
      _transactionPool.add(transaction);

      return transaction;
    } catch (e) {
      throw Exception('Failed to store data: $e');
    }
  }

  Future<BlockchainTransaction> _storeDataOnEthereum(
    String dataId,
    String dataHash,
    String metadata,
  ) async {
    if (_contract == null || _credentials == null) {
      throw Exception('Contract or credentials not initialized');
    }

    final function = _contract!.function('storeData');
    final params = [dataId, dataHash, metadata];

    final transaction = await _web3client!.sendTransaction(
      credentials: _credentials!,
      transaction: Transaction.callContract(
        contract: _contract!,
        function: function,
        parameters: params,
      ),
    );

    final receipt = await _web3client!.getTransactionReceipt(transaction);

    return BlockchainTransaction(
      hash: transaction,
      blockNumber: receipt.blockNumber?.toInt(),
      timestamp: DateTime.now(),
      status: receipt.status == 1 ? TransactionStatus.confirmed : TransactionStatus.failed,
      gasUsed: receipt.gasUsed?.toInt(),
      type: TransactionType.store,
      dataId: dataId,
    );
  }

  Future<BlockchainTransaction> _storeDataOnLocalBlockchain(
    String dataId,
    Map<String, dynamic> data,
    String dataHash,
    String? metadata,
  ) async {
    // Create new block
    final previousBlock = _getLatestBlock();
    final blockIndex = previousBlock?.index ?? 0;
    final previousHash = previousBlock?.hash ?? '0' * 64;

    final blockData = {
      'action': 'store',
      'dataId': dataId,
      'dataHash': dataHash,
      'metadata': metadata,
      'owner': _accountAddress ?? 'local',
    };

    final newBlock = BlockchainBlock(
      index: blockIndex + 1,
      timestamp: DateTime.now(),
      previousHash: previousHash,
      data: [blockData],
      nonce: _generateNonce(),
      hash: '',
    );

    // Mine block
    final minedBlock = _mineBlock(newBlock);

    // Store in ledger
    final record = BlockchainRecord(
      id: 'block_${minedBlock.index}',
      type: 'block',
      data: minedBlock.toMap(),
      timestamp: minedBlock.timestamp,
      hash: minedBlock.hash,
      previousHash: minedBlock.previousHash,
    );

    _localLedger[record.id] = record;

    return BlockchainTransaction(
      hash: minedBlock.hash,
      blockNumber: minedBlock.index,
      timestamp: minedBlock.timestamp,
      status: TransactionStatus.confirmed,
      gasUsed: 0,
      type: TransactionType.store,
      dataId: dataId,
    );
  }

  /// Verify data integrity
  Future<VerificationResult> verifyData(String dataId, Map<String, dynamic> data) async {
    try {
      final dataHash = _calculateDataHash(data);

      if (!_useLocalBlockchain) {
        return await _verifyDataOnEthereum(dataId, dataHash);
      } else {
        return await _verifyDataOnLocalBlockchain(dataId, dataHash);
      }
    } catch (e) {
      return VerificationResult(
        isValid: false,
        error: 'Verification failed: $e',
      );
    }
  }

  Future<VerificationResult> _verifyDataOnEthereum(String dataId, String dataHash) async {
    if (_contract == null) {
      return VerificationResult(isValid: false, error: 'Contract not initialized');
    }

    final function = _contract!.function('verifyData');
    final result = await _web3client!.call(
      contract: _contract!,
      function: function,
      params: [dataId],
    );

    final exists = result[0] as bool;
    final owner = result[1] as String;
    final storedHash = bytesToHex(result[2] as Uint8List);
    final timestamp = result[3] as BigInt;

    return VerificationResult(
      isValid: exists && storedHash == dataHash,
      owner: owner,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()),
      storedHash: storedHash,
    );
  }

  Future<VerificationResult> _verifyDataOnLocalBlockchain(String dataId, String dataHash) async {
    // Search through local ledger for the data
    for (final record in _localLedger.values) {
      if (record.type == 'block') {
        final block = BlockchainBlock.fromMap(record.data);
        for (final blockData in block.data) {
          if (blockData['dataId'] == dataId) {
            return VerificationResult(
              isValid: blockData['dataHash'] == dataHash,
              owner: blockData['owner'],
              timestamp: block.timestamp,
              storedHash: blockData['dataHash'],
            );
          }
        }
      }
    }

    return VerificationResult(
      isValid: false,
      error: 'Data not found in local blockchain',
    );
  }

  /// Get data by owner
  Future<List<String>> getDataByOwner(String owner) async {
    try {
      if (!_useLocalBlockchain) {
        return await _getDataByOwnerOnEthereum(owner);
      } else {
        return await _getDataByOwnerOnLocalBlockchain(owner);
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getDataByOwnerOnEthereum(String owner) async {
    if (_contract == null) return [];

    final function = _contract!.function('getDataByOwner');
    final result = await _web3client!.call(
      contract: _contract!,
      function: function,
      params: [EthereumAddress.fromHex(owner)],
    );

    return List<String>.from(result[0] as List<dynamic>);
  }

  Future<List<String>> _getDataByOwnerOnLocalBlockchain(String owner) async {
    final dataIds = <String>[];

    for (final record in _localLedger.values) {
      if (record.type == 'block') {
        final block = BlockchainBlock.fromMap(record.data);
        for (final blockData in block.data) {
          if (blockData['owner'] == owner && blockData['action'] == 'store') {
            dataIds.add(blockData['dataId']);
          }
        }
      }
    }

    return dataIds;
  }

  /// Generate proof of existence
  BlockchainProof generateProof(String dataId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final proof = BlockchainProof(
      dataId: dataId,
      timestamp: timestamp,
      proof: _calculateProof(dataId, timestamp),
      signature: _signProof(dataId, timestamp),
    );

    _proofs[dataId] = proof;
    return proof;
  }

  /// Verify proof of existence
  bool verifyProof(BlockchainProof proof) {
    // Verify proof integrity
    final calculatedProof = _calculateProof(proof.dataId, proof.timestamp);
    if (calculatedProof != proof.proof) {
      return false;
    }

    // Verify signature
    return _verifySignature(proof.dataId, proof.timestamp, proof.signature);
  }

  /// Mining (for local blockchain)
  void _startMining() {
    Timer.periodic(_blockTime, (_) {
      if (_transactionPool.isNotEmpty) {
        _minePendingTransactions();
      }
    });
  }

  void _minePendingTransactions() {
    final transactions = _transactionPool.take(_blockSize).toList();
    if (transactions.isEmpty) return;

    final previousBlock = _getLatestBlock();
    final blockIndex = previousBlock?.index ?? 0;
    final previousHash = previousBlock?.hash ?? '0' * 64;

    final newBlock = BlockchainBlock(
      index: blockIndex + 1,
      timestamp: DateTime.now(),
      previousHash: previousHash,
      data: transactions.map((t) => t.toMap()).toList(),
      nonce: _generateNonce(),
      hash: '',
    );

    final minedBlock = _mineBlock(newBlock);

    // Store mined block
    final record = BlockchainRecord(
      id: 'block_${minedBlock.index}',
      type: 'block',
      data: minedBlock.toMap(),
      timestamp: minedBlock.timestamp,
      hash: minedBlock.hash,
      previousHash: minedBlock.previousHash,
    );

    _localLedger[record.id] = record;

    // Remove mined transactions from pool
    _transactionPool.removeRange(0, transactions.length);
  }

  BlockchainBlock _mineBlock(BlockchainBlock block) {
    int nonce = 0;
    String hash;

    do {
      nonce++;
      hash = _calculateBlockHash(
        block.index,
        block.timestamp,
        block.previousHash,
        block.data,
        nonce,
      );
    } while (!hash.startsWith('0' * _difficulty));

    return block.copyWith(hash: hash, nonce: nonce);
  }

  BlockchainBlock? _getLatestBlock() {
    BlockchainBlock? latestBlock;
    
    for (final record in _localLedger.values) {
      if (record.type == 'block') {
        final block = BlockchainBlock.fromMap(record.data);
        if (latestBlock == null || block.index > latestBlock.index) {
          latestBlock = block;
        }
      }
    }

    return latestBlock;
  }

  /// Utility Methods
  String _calculateDataHash(Map<String, dynamic> data) {
    final dataString = jsonEncode(data);
    final bytes = utf8.encode(dataString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _calculateBlockHash(
    int index,
    DateTime timestamp,
    String previousHash,
    List<dynamic> data,
    int nonce,
  ) {
    final blockData = '$index$timestamp$previousHash$data$nonce';
    final bytes = utf8.encode(blockData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _calculateProof(String dataId, int timestamp) {
    final proofData = '$dataId$timestamp';
    final bytes = utf8.encode(proofData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _signProof(String dataId, int timestamp) {
    // Simplified signature - in production, use proper cryptographic signing
    final proofData = '$dataId$timestamp';
    final bytes = utf8.encode(proofData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _verifySignature(String dataId, int timestamp, String signature) {
    // Simplified verification - in production, use proper cryptographic verification
    final calculatedSignature = _signProof(dataId, timestamp);
    return calculatedSignature == signature;
  }

  int _generateNonce() {
    return Random().nextInt(999999);
  }

  /// Get blockchain statistics
  Map<String, dynamic> getBlockchainStats() {
    return {
      'isInitialized': _isInitialized,
      'isConnected': _isConnected,
      'networkName': _networkName,
      'chainId': _chainId,
      'accountAddress': _accountAddress,
      'balance': _balance?.toString(),
      'useLocalBlockchain': _useLocalBlockchain,
      'localLedgerSize': _localLedger.length,
      'transactionPoolSize': _transactionPool.length,
      'proofCount': _proofs.length,
      'enableMining': _enableMining,
      'difficulty': _difficulty,
      'blockSize': _blockSize,
      'blockTime': _blockTime.inSeconds,
    };
  }

  /// Dispose blockchain engine
  Future<void> dispose() async {
    _web3client?.dispose();
    _localLedger.clear();
    _transactionPool.clear();
    _proofs.clear();
    _isInitialized = false;
    _isConnected = false;
  }
}

// Blockchain Models
class BlockchainRecord {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String hash;
  final String previousHash;

  const BlockchainRecord({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.hash,
    required this.previousHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'hash': hash,
      'previousHash': previousHash,
    };
  }

  factory BlockchainRecord.fromMap(Map<String, dynamic> map) {
    return BlockchainRecord(
      id: map['id'],
      type: map['type'],
      data: Map<String, dynamic>.from(map['data']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      hash: map['hash'],
      previousHash: map['previousHash'],
    );
  }
}

class BlockchainBlock {
  final int index;
  final DateTime timestamp;
  final String previousHash;
  final List<dynamic> data;
  final int nonce;
  final String hash;

  const BlockchainBlock({
    required this.index,
    required this.timestamp,
    required this.previousHash,
    required this.data,
    required this.nonce,
    required this.hash,
  });

  BlockchainBlock copyWith({
    int? index,
    DateTime? timestamp,
    String? previousHash,
    List<dynamic>? data,
    int? nonce,
    String? hash,
  }) {
    return BlockchainBlock(
      index: index ?? this.index,
      timestamp: timestamp ?? this.timestamp,
      previousHash: previousHash ?? this.previousHash,
      data: data ?? this.data,
      nonce: nonce ?? this.nonce,
      hash: hash ?? this.hash,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'previousHash': previousHash,
      'data': data,
      'nonce': nonce,
      'hash': hash,
    };
  }

  factory BlockchainBlock.fromMap(Map<String, dynamic> map) {
    return BlockchainBlock(
      index: map['index'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      previousHash: map['previousHash'],
      data: map['data'],
      nonce: map['nonce'],
      hash: map['hash'],
    );
  }
}

class BlockchainTransaction {
  final String hash;
  final int? blockNumber;
  final DateTime timestamp;
  final TransactionStatus status;
  final int? gasUsed;
  final TransactionType type;
  final String dataId;

  const BlockchainTransaction({
    required this.hash,
    this.blockNumber,
    required this.timestamp,
    required this.status,
    this.gasUsed,
    required this.type,
    required this.dataId,
  });

  Map<String, dynamic> toMap() {
    return {
      'hash': hash,
      'blockNumber': blockNumber,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'gasUsed': gasUsed,
      'type': type.name,
      'dataId': dataId,
    };
  }
}

class BlockchainProof {
  final String dataId;
  final int timestamp;
  final String proof;
  final String signature;

  const BlockchainProof({
    required this.dataId,
    required this.timestamp,
    required this.proof,
    required this.signature,
  });
}

class VerificationResult {
  final bool isValid;
  final String? owner;
  final DateTime? timestamp;
  final String? storedHash;
  final String? error;

  const VerificationResult({
    required this.isValid,
    this.owner,
    this.timestamp,
    this.storedHash,
    this.error,
  });
}

// Enums
enum TransactionStatus {
  pending,
  confirmed,
  failed,
}

enum TransactionType {
  store,
  update,
  delete,
}
