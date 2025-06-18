#!/usr/bin/env bash
### DOC
# docker-cleanup - Clean up Docker containers and images
# Removes stopped containers and dangling images to free up space
### DOC
set -euo pipefail

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Docker not found. Please install Docker first." >&2
  exit 1
fi

main() {
  local force="${1:-}"
  
  echo "🐳 Docker Cleanup Tool"
  echo "======================"
  
  if [[ "$force" != "--force" ]]; then
    echo "This will remove:"
    echo "  • All stopped containers"
    echo "  • All dangling images"
    echo "  • All unused networks"
    echo "  • All unused volumes (with --volumes flag)"
    echo
    read -p "Continue? [y/N]: " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Cleanup cancelled"
      return 0
    fi
  fi
  
  echo
  echo "Cleaning up stopped containers..."
  if containers=$(docker ps -aq --filter "status=exited"); then
    if [[ -n "$containers" ]]; then
      echo "$containers" | xargs docker rm
      echo "  ✓ Removed stopped containers"
    else
      echo "  ✓ No stopped containers to remove"
    fi
  fi
  
  echo
  echo "Cleaning up dangling images..."
  if images=$(docker images -q --filter "dangling=true"); then
    if [[ -n "$images" ]]; then
      echo "$images" | xargs docker rmi
      echo "  ✓ Removed dangling images"
    else
      echo "  ✓ No dangling images to remove"
    fi
  fi
  
  echo
  echo "Cleaning up unused networks..."
  docker network prune -f
  echo "  ✓ Removed unused networks"
  
  echo
  echo "🎉 Docker cleanup completed!"
  echo
  echo "To also remove unused volumes, run:"
  echo "  docker volume prune"
}

main "$@"