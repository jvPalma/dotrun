# Docker Management Scripts

Collection of Docker container and image management scripts for development workflows.

## Container Cleanup

Clean up stopped containers, unused images, and volumes.

```bash
#!/usr/bin/env bash
### DOC
# Comprehensive Docker cleanup for development
### DOC
set -euo pipefail

source "$DRUN_CONFIG/helpers/pkg.sh"

validatePkg docker

echo "🧹 Docker Cleanup Starting"

# Show current Docker usage
echo "📊 Current Docker Usage:"
echo "   Containers: $(docker ps -a --format "table {{.Names}}" | wc -l) total"
echo "   Images: $(docker images --format "table {{.Repository}}" | wc -l) total"
echo "   Volumes: $(docker volume ls --format "table {{.Name}}" | wc -l) total"

# Remove stopped containers
echo ""
echo "🗑️  Removing stopped containers..."
STOPPED_CONTAINERS=$(docker ps -a -q -f status=exited)
if [ -n "$STOPPED_CONTAINERS" ]; then
    docker rm $STOPPED_CONTAINERS
    echo "   ✅ Removed $(echo $STOPPED_CONTAINERS | wc -w) stopped containers"
else
    echo "   ✨ No stopped containers to remove"
fi

# Remove dangling images
echo ""
echo "🖼️  Removing dangling images..."
DANGLING_IMAGES=$(docker images -f "dangling=true" -q)
if [ -n "$DANGLING_IMAGES" ]; then
    docker rmi $DANGLING_IMAGES
    echo "   ✅ Removed $(echo $DANGLING_IMAGES | wc -w) dangling images"
else
    echo "   ✨ No dangling images to remove"
fi

# Remove unused volumes
echo ""
echo "💾 Removing unused volumes..."
UNUSED_VOLUMES=$(docker volume ls -f dangling=true -q)
if [ -n "$UNUSED_VOLUMES" ]; then
    docker volume rm $UNUSED_VOLUMES
    echo "   ✅ Removed $(echo $UNUSED_VOLUMES | wc -w) unused volumes"
else
    echo "   ✨ No unused volumes to remove"
fi

# Remove unused networks
echo ""
echo "🌐 Removing unused networks..."
docker network prune -f

# Show disk space saved
echo ""
echo "📊 Final Docker Usage:"
echo "   Containers: $(docker ps -a --format "table {{.Names}}" | wc -l) total"
echo "   Images: $(docker images --format "table {{.Repository}}" | wc -l) total"
echo "   Volumes: $(docker volume ls --format "table {{.Name}}" | wc -l) total"

echo "✅ Docker cleanup completed!"
```

**Usage:** `drun add docker/cleanup && drun docker/cleanup`

---

## Development Environment Setup

Quick setup for common development containers.

```bash
#!/usr/bin/env bash
### DOC
# Setup development environment with Docker containers
### DOC
set -euo pipefail

source "$DRUN_CONFIG/helpers/pkg.sh"

validatePkg docker

# Configuration
NETWORK_NAME="dev-network"
DB_CONTAINER="dev-postgres"
REDIS_CONTAINER="dev-redis"
POSTGRES_PASSWORD="devpassword"
POSTGRES_DB="devdb"

echo "🚀 Setting up development environment"

# Create development network if it doesn't exist
if ! docker network ls | grep -q "$NETWORK_NAME"; then
    echo "🌐 Creating development network: $NETWORK_NAME"
    docker network create "$NETWORK_NAME"
else
    echo "✅ Development network already exists: $NETWORK_NAME"
fi

# Setup PostgreSQL container
echo ""
echo "🐘 Setting up PostgreSQL container"
if docker ps -a | grep -q "$DB_CONTAINER"; then
    echo "   📋 Container $DB_CONTAINER already exists"
    if ! docker ps | grep -q "$DB_CONTAINER"; then
        echo "   🔄 Starting existing container"
        docker start "$DB_CONTAINER"
    fi
else
    echo "   🆕 Creating new PostgreSQL container"
    docker run -d \
        --name "$DB_CONTAINER" \
        --network "$NETWORK_NAME" \
        -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
        -e POSTGRES_DB="$POSTGRES_DB" \
        -p 5432:5432 \
        -v postgres_data:/var/lib/postgresql/data \
        postgres:15-alpine
fi

# Setup Redis container
echo ""
echo "🔴 Setting up Redis container"
if docker ps -a | grep -q "$REDIS_CONTAINER"; then
    echo "   📋 Container $REDIS_CONTAINER already exists"
    if ! docker ps | grep -q "$REDIS_CONTAINER"; then
        echo "   🔄 Starting existing container"
        docker start "$REDIS_CONTAINER"
    fi
else
    echo "   🆕 Creating new Redis container"
    docker run -d \
        --name "$REDIS_CONTAINER" \
        --network "$NETWORK_NAME" \
        -p 6379:6379 \
        -v redis_data:/data \
        redis:7-alpine
fi

# Wait for services to be ready
echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check service health
echo ""
echo "🏥 Checking service health:"

# Check PostgreSQL
if docker exec "$DB_CONTAINER" pg_isready > /dev/null 2>&1; then
    echo "   ✅ PostgreSQL is ready"
    echo "      Host: localhost:5432"
    echo "      Database: $POSTGRES_DB"
    echo "      Username: postgres"
    echo "      Password: $POSTGRES_PASSWORD"
else
    echo "   ❌ PostgreSQL is not ready"
fi

# Check Redis
if docker exec "$REDIS_CONTAINER" redis-cli ping | grep -q "PONG"; then
    echo "   ✅ Redis is ready"
    echo "      Host: localhost:6379"
else
    echo "   ❌ Redis is not ready"
fi

echo ""
echo "✅ Development environment setup completed!"
echo ""
echo "🔧 Useful commands:"
echo "   Stop all: docker stop $DB_CONTAINER $REDIS_CONTAINER"
echo "   Remove all: docker rm $DB_CONTAINER $REDIS_CONTAINER"
echo "   View logs: docker logs $DB_CONTAINER"
```

**Usage:** `drun add docker/dev-setup && drun docker/dev-setup`

---

## Container Monitoring

Monitor running containers and their resource usage.

```bash
#!/usr/bin/env bash
### DOC
# Monitor Docker containers and resource usage
### DOC
set -euo pipefail

source "$DRUN_CONFIG/helpers/pkg.sh"

validatePkg docker

# Configuration
REFRESH_INTERVAL="${1:-5}"
MAX_ITERATIONS="${2:-10}"

echo "📊 Docker Container Monitoring"
echo "=============================="
echo "Refresh interval: ${REFRESH_INTERVAL}s"
echo "Max iterations: $MAX_ITERATIONS"
echo ""

# Function to display container stats
show_container_stats() {
    local iteration=$1

    echo "📈 Iteration $iteration/$([ "$MAX_ITERATIONS" = "0" ] && echo "∞" || echo "$MAX_ITERATIONS") - $(date)"
    echo ""

    # Running containers count
    RUNNING_COUNT=$(docker ps --format "table {{.Names}}" | wc -l)
    echo "🏃 Running containers: $RUNNING_COUNT"

    if [ "$RUNNING_COUNT" -gt 0 ]; then
        # Container status overview
        echo ""
        echo "📋 Container Overview:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | \
        while IFS= read -r line; do
            echo "   $line"
        done

        # Resource usage
        echo ""
        echo "💾 Resource Usage:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | \
        while IFS= read -r line; do
            echo "   $line"
        done

        # Check for high resource usage
        echo ""
        echo "⚠️  Resource Alerts:"
        docker stats --no-stream --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemPerc}}" | \
        while IFS=$'\t' read -r name cpu mem; do
            cpu_num=$(echo "$cpu" | sed 's/%//')
            mem_num=$(echo "$mem" | sed 's/%//')

            if (( $(echo "$cpu_num > 80" | bc -l) )); then
                echo "   🔥 High CPU: $name ($cpu)"
            fi

            if (( $(echo "$mem_num > 80" | bc -l) )); then
                echo "   🧠 High Memory: $name ($mem)"
            fi
        done
    else
        echo ""
        echo "😴 No containers are currently running"
    fi

    echo ""
    echo "----------------------------------------"
}

# Main monitoring loop
iteration=1
while [ "$MAX_ITERATIONS" -eq 0 ] || [ "$iteration" -le "$MAX_ITERATIONS" ]; do
    clear
    show_container_stats "$iteration"

    if [ "$MAX_ITERATIONS" -ne 0 ] && [ "$iteration" -eq "$MAX_ITERATIONS" ]; then
        break
    fi

    echo "Press Ctrl+C to stop monitoring..."
    sleep "$REFRESH_INTERVAL"
    iteration=$((iteration + 1))
done

echo "🏁 Monitoring completed!"
```

**Usage:** `drun add docker/monitor && drun docker/monitor [interval] [max_iterations]`

---

## Image Optimization

Optimize Docker images and clean up build cache.

```bash
#!/usr/bin/env bash
### DOC
# Optimize Docker images and clean build cache
### DOC
set -euo pipefail

source "$DRUN_CONFIG/helpers/pkg.sh"

validatePkg docker

echo "🔧 Docker Image Optimization"

# Show current usage
echo "📊 Current Docker Usage:"
TOTAL_IMAGES=$(docker images | wc -l)
TOTAL_SIZE=$(docker images --format "table {{.Size}}" | grep -v "SIZE" | \
    sed 's/MB//' | sed 's/GB/000/' | sed 's/KB/0.001/' | \
    awk '{sum += $1} END {printf "%.1f", sum}')

echo "   Total images: $TOTAL_IMAGES"
echo "   Estimated total size: ${TOTAL_SIZE}MB"

# Find large images
echo ""
echo "🐋 Largest Images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | \
head -10 | while IFS= read -r line; do
    echo "   $line"
done

# Find dangling images
echo ""
echo "👻 Dangling Images:"
DANGLING_COUNT=$(docker images -f "dangling=true" | wc -l)
if [ "$DANGLING_COUNT" -gt 1 ]; then
    echo "   Found $((DANGLING_COUNT - 1)) dangling images"
    docker images -f "dangling=true" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | \
    tail -n +2 | head -5 | while IFS= read -r line; do
        echo "     $line"
    done
else
    echo "   ✨ No dangling images found"
fi

# Find unused images
echo ""
echo "🗑️  Potentially Unused Images:"
# Images not used by any container
UNUSED_IMAGES=$(comm -23 \
    <(docker images --format "{{.Repository}}:{{.Tag}}" | sort) \
    <(docker ps -a --format "{{.Image}}" | sort | uniq) | head -5)

if [ -n "$UNUSED_IMAGES" ]; then
    echo "$UNUSED_IMAGES" | while IFS= read -r image; do
        echo "   $image"
    done
else
    echo "   ✨ All images appear to be in use"
fi

# Optimization options
echo ""
echo "🛠️  Optimization Options:"
echo "   1. Remove dangling images"
echo "   2. Remove unused images (be careful!)"
echo "   3. Clean build cache"
echo "   4. System prune (removes everything unused)"
echo "   5. Show detailed image history"
echo ""

read -p "Select option (1-5, or 'q' to quit): " choice

case $choice in
    1)
        echo "🗑️  Removing dangling images..."
        docker image prune -f
        ;;
    2)
        echo "⚠️  This will remove images not used by any container!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker image prune -a -f
        fi
        ;;
    3)
        echo "🧹 Cleaning build cache..."
        docker builder prune -f
        ;;
    4)
        echo "⚠️  This will remove all unused containers, networks, images!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker system prune -a -f
        fi
        ;;
    5)
        echo "🔍 Enter image name to inspect:"
        read -r image_name
        if [ -n "$image_name" ]; then
            docker history "$image_name" --human
        fi
        ;;
    q)
        echo "👋 Exiting..."
        ;;
    *)
        echo "❌ Invalid option"
        ;;
esac

# Show final usage
echo ""
echo "📊 Final Docker Usage:"
FINAL_IMAGES=$(docker images | wc -l)
echo "   Total images: $FINAL_IMAGES"

echo "✅ Image optimization completed!"
```

**Usage:** `drun add docker/optimize && drun docker/optimize`
