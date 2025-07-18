#!/bin/bash

# Model switcher for SimpleBrain
set -euo pipefail

MODELS_DIR="./models"
CURRENT_MODEL="model.gguf"

show_models() {
    echo "📋 Available models:"
    ls -lh "$MODELS_DIR"/*.gguf | grep -v "$CURRENT_MODEL" | awk '{print "  " $9 " (" $5 ")"}'
    echo
    echo "🎯 Current model:"
    if [ -L "$MODELS_DIR/$CURRENT_MODEL" ]; then
        echo "  $CURRENT_MODEL -> $(readlink "$MODELS_DIR/$CURRENT_MODEL")"
    else
        echo "  $CURRENT_MODEL (direct file)"
    fi
}

switch_model() {
    local new_model="$1"
    
    if [ ! -f "$MODELS_DIR/$new_model" ]; then
        echo "❌ Model not found: $new_model"
        exit 1
    fi
    
    echo "🔄 Switching from $(readlink "$MODELS_DIR/$CURRENT_MODEL" 2>/dev/null || echo "current") to $new_model"
    
    # Stop container
    ./automate_local_llm.sh stop
    
    # Switch model
    cd "$MODELS_DIR"
    rm -f "$CURRENT_MODEL"
    ln -s "$new_model" "$CURRENT_MODEL"
    cd ..
    
    # Start container with new model
    ./automate_local_llm.sh start
    
    echo "✅ Model switched to $new_model successfully!"
}

case "${1:-}" in
    list|ls)
        show_models
        ;;
    switch)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 switch <model_file>"
            show_models
            exit 1
        fi
        switch_model "$2"
        ;;
    *)
        echo "SimpleBrain Model Switcher"
        echo
        echo "Usage:"
        echo "  $0 list          # Show available models"
        echo "  $0 switch <model> # Switch to specified model"
        echo
        show_models
        ;;
esac