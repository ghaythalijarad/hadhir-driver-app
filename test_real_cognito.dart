#!/usr/bin/env dart
// ignore_for_file: avoid_print

// Test script to verify real AWS Cognito registration
// Run with: dart test_real_cognito.dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('Testing Real AWS Cognito Configuration...');
  print('');
  
  // Test 1: Verify Cognito User Pool exists
  print('Test 1: Checking Cognito User Pool...');
  final userPoolId = 'us-east-1_xDptXxzaI';
  final clientId = 'vjcumd2cck66kprpc86nmgs9t';
  final region = 'us-east-1';
  
  print('   User Pool ID: $userPoolId');
  print('   Client ID: $clientId');
  print('   Region: $region');
  print('');
  
  // Test 2: Verify AWS CLI connectivity
  print('Test 2: Testing AWS CLI connectivity...');
  try {
    final result = await Process.run('aws', [
      'cognito-idp',
      'describe-user-pool',
      '--user-pool-id', userPoolId,
      '--profile', 'wizz-drivers-ghayth-dev'
    ]);
    
    if (result.exitCode == 0) {
      final response = jsonDecode(result.stdout);
      final poolName = response['UserPool']['Name'];
      print('   ✅ User Pool found: $poolName');
    } else {
      print('   ❌ Failed to describe user pool: ${result.stderr}');
    }
  } catch (e) {
    print('   ❌ AWS CLI error: $e');
  }
  print('');
  
  // Test 3: Check User Pool Client configuration
  print('Test 3: Checking User Pool Client...');
  try {
    final result = await Process.run('aws', [
      'cognito-idp',
      'describe-user-pool-client',
      '--user-pool-id', userPoolId,
      '--client-id', clientId,
      '--profile', 'wizz-drivers-ghayth-dev'
    ]);
    
    if (result.exitCode == 0) {
      final response = jsonDecode(result.stdout);
      final client = response['UserPoolClient'];
      print('   ✅ Client found: ${client['ClientName']}');
      print('   ✅ Auth flows: ${client['ExplicitAuthFlows']}');
      print('   ✅ Username attributes: ${client['UsernameAttributes']}');
    } else {
      print('   ❌ Failed to describe client: ${result.stderr}');
    }
  } catch (e) {
    print('   ❌ AWS CLI error: $e');
  }
  print('');
  
  print('Next Steps:');
  print('   1. Open iOS Simulator');
  print('   2. Navigate to registration screen');
  print('   3. Test with real phone number or email');
  print('   4. Verify OTP/verification process');
  print('');
}
