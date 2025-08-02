#!/usr/bin/env python3

import json
import os

# Read the model.safetensors.index.json to see the weight mapping
index_path = "KickbackApp/Resources/Models/model.safetensors.index.json"

if os.path.exists(index_path):
    with open(index_path, 'r') as f:
        index_data = json.load(f)
    
    print("Available weights in the model:")
    print("=" * 50)
    
    weight_map = index_data.get('weight_map', {})
    
    # Look for embedding-related weights
    embedding_weights = [k for k in weight_map.keys() if 'embed' in k.lower()]
    print(f"\nEmbedding weights ({len(embedding_weights)}):")
    for weight in sorted(embedding_weights):
        print(f"  {weight}")
    
    # Look for token-related weights
    token_weights = [k for k in weight_map.keys() if 'token' in k.lower()]
    print(f"\nToken weights ({len(token_weights)}):")
    for weight in sorted(token_weights):
        print(f"  {weight}")
    
    # Look for norm weights
    norm_weights = [k for k in weight_map.keys() if 'norm' in k.lower()]
    print(f"\nNorm weights (first 10):")
    for weight in sorted(norm_weights)[:10]:
        print(f"  {weight}")
    
    # Look for transformer layer weights
    transformer_weights = [k for k in weight_map.keys() if 'transformer' in k.lower()]
    print(f"\nTransformer weights (first 10):")
    for weight in sorted(transformer_weights)[:10]:
        print(f"  {weight}")
    
    print(f"\nTotal weights: {len(weight_map)}")
    
else:
    print(f"Index file not found at {index_path}")
    print("Looking for safetensors files...")
    models_dir = "KickbackApp/Resources/Models"
    if os.path.exists(models_dir):
        files = os.listdir(models_dir)
        safetensors_files = [f for f in files if f.endswith('.safetensors')]
        print(f"Found safetensors files: {safetensors_files}")
    else:
        print(f"Models directory not found at {models_dir}")