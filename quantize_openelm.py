#!/usr/bin/env python3
"""
Quantize OpenELM-3B model to 8-bit for iOS memory optimization.
Reduces model size from 5.7GB to ~2.85GB while maintaining accuracy.
"""

import os
import sys
from pathlib import Path

try:
    import mlx.core as mx
    import numpy as np
    from safetensors import safe_open
    from safetensors.numpy import save_file
except ImportError as e:
    print(f"Missing required package: {e}")
    print("Install with: pip install mlx safetensors numpy")
    sys.exit(1)

def quantize_openelm_model():
    """Quantize OpenELM-3B model to 8-bit."""
    
    # Paths to the model files
    model_dir = Path("KickbackApp/Resources/Models")
    model_files = [
        "model-00001-of-00002.safetensors",
        "model-00002-of-00002.safetensors"
    ]
    
    print("🔄 Starting OpenELM-3B quantization to 8-bit...")
    print(f"📁 Model directory: {model_dir}")
    
    # Check if files exist
    for file in model_files:
        file_path = model_dir / file
        if not file_path.exists():
            print(f"❌ Error: {file_path} not found")
            return False
    
    # Load all weights
    all_weights = {}
    total_size_mb = 0
    
    for file in model_files:
        file_path = model_dir / file
        print(f"📥 Loading {file}...")
        
        # Load using MLX's built-in loader
        weights = mx.load(str(file_path))
        for key, tensor in weights.items():
            all_weights[key] = tensor
            
            # Calculate size
            size_mb = tensor.nbytes / (1024 * 1024)
            total_size_mb += size_mb
    
    print(f"✅ Loaded {len(all_weights)} tensors ({total_size_mb:.1f} MB)")
    
    # Quantize weights
    quantized_weights = {}
    quantized_size_mb = 0
    
    print("🔄 Quantizing weights to 8-bit...")
    
    # Debug: Check what types we have
    dtype_counts = {}
    shape_counts = {}
    for key, weight in all_weights.items():
        dtype_counts[str(weight.dtype)] = dtype_counts.get(str(weight.dtype), 0) + 1
        shape_len = len(weight.shape)
        shape_counts[shape_len] = shape_counts.get(shape_len, 0) + 1
    
    print(f"📊 Data types: {dtype_counts}")
    print(f"📊 Tensor dimensions: {shape_counts}")
    
    for key, weight in all_weights.items():
        if weight.dtype in [mx.float32, mx.float16, mx.bfloat16] and len(weight.shape) >= 2:
            # Manual quantization to int8 for effective size reduction
            # Scale and quantize to [-128, 127] range
            weight_min = mx.min(weight)
            weight_max = mx.max(weight)
            scale = (weight_max - weight_min) / 255.0
            zero_point = weight_min
            
            # Quantize to int8
            quantized_float = (weight - zero_point) / scale
            quantized_int8 = mx.clip(quantized_float, 0, 255) - 128
            quantized_int8 = quantized_int8.astype(mx.int8)
            
            # Store quantized tensor with metadata for dequantization
            quantized_weights[key] = quantized_int8
            quantized_weights[f"{key}.scale"] = scale
            quantized_weights[f"{key}.zero_point"] = zero_point
            
            # Calculate actual size reduction (int8 vs float16/32)
            original_bytes = weight.nbytes
            quantized_bytes = quantized_int8.nbytes + scale.nbytes + zero_point.nbytes
            quantized_size_mb += quantized_bytes / (1024 * 1024)
            
            if len([k for k in quantized_weights.keys() if not k.endswith('.scale') and not k.endswith('.zero_point')]) <= 5:
                print(f"  📦 {key}: {weight.shape} ({weight.dtype} → int8, {original_bytes//1024}KB → {quantized_bytes//1024}KB)")
        else:
            # Keep non-weight tensors as-is (embeddings, norms, etc.)
            quantized_weights[key] = weight
            quantized_size_mb += weight.nbytes / (1024 * 1024)
    
    print(f"✅ Quantized {len(quantized_weights)} tensors")
    print(f"📊 Size reduction: {total_size_mb:.1f} MB → {quantized_size_mb:.1f} MB ({quantized_size_mb/total_size_mb*100:.1f}%)")
    
    # Save quantized model
    output_path = model_dir / "model-q8_0.safetensors"
    print(f"💾 Saving quantized model to {output_path}...")
    
    try:
        mx.save_safetensors(str(output_path), quantized_weights)
        
        # Verify the saved file
        actual_size_mb = output_path.stat().st_size / (1024 * 1024)
        print(f"✅ Quantized model saved successfully!")
        print(f"📁 File size: {actual_size_mb:.1f} MB")
        print(f"🎯 Memory savings: {total_size_mb - actual_size_mb:.1f} MB ({(1 - actual_size_mb/total_size_mb)*100:.1f}%)")
        
        return True
        
    except Exception as e:
        print(f"❌ Error saving quantized model: {e}")
        return False

def main():
    """Main quantization process."""
    print("🚀 OpenELM-3B Quantization Tool")
    print("=" * 50)
    
    if quantize_openelm_model():
        print("\n🎉 Quantization completed successfully!")
        print("📱 Your iOS app can now use the 8-bit quantized model for better memory efficiency.")
        print("🔧 The app will automatically detect and use model-q8_0.safetensors")
    else:
        print("\n❌ Quantization failed. Please check the error messages above.")
        sys.exit(1)

if __name__ == "__main__":
    main()