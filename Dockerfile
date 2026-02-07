# Build stage
FROM hexpm/elixir:1.18.4-erlang-28.0.2-debian-bookworm-20250811


RUN apt-get update -y && \
    apt-get install -y git curl postgresql-client \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy application code
COPY . .

# Expose port
EXPOSE 4500

# Run tests
CMD ["mix", "test"]
