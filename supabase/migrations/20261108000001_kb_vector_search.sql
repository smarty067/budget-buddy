-- ==============================================================================
-- Migration: 20261108000001_kb_vector_search.sql
-- Description: Idempotent pgvector extension, kb_chunks table, indexes, and match function
-- ==============================================================================

-- 1. Enable pgvector extension in the extensions schema
create extension if not exists vector with schema extensions;

-- 2. Knowledge Base Chunks Table
create table if not exists public.kb_chunks (
    id bigserial primary key,
    source text not null,
    title text not null,
    content text not null,
    embedding extensions.vector(384) not null,
    updated_at timestamptz not null default now()
);

-- 3. Row Level Security: Authenticated users can SELECT only; no insert/update/delete policies
alter table public.kb_chunks enable row level security;

drop policy if exists "kb_chunks: read for authenticated" on public.kb_chunks;
create policy "kb_chunks: read for authenticated"
    on public.kb_chunks
    for select
    to authenticated
    using (true);

-- 4. Indexes
create index if not exists idx_kb_chunks_source
    on public.kb_chunks (source);

create index if not exists idx_kb_chunks_embedding_hnsw
    on public.kb_chunks using hnsw (embedding extensions.vector_cosine_ops);

-- 5. Vector search match function
create or replace function public.match_kb_chunks(
    query_embedding extensions.vector(384),
    match_count int default 3,
    min_similarity float default 0.55
)
returns table (
    id bigint,
    title text,
    content text,
    similarity float
)
language sql
stable
set search_path = public, extensions
as $$
    select
        kc.id,
        kc.title,
        kc.content,
        (1 - (kc.embedding <=> query_embedding))::float as similarity
    from public.kb_chunks kc
    where (1 - (kc.embedding <=> query_embedding)) >= min_similarity
    order by kc.embedding <=> query_embedding
    limit match_count;
$$;

-- Grant execute permission to authenticated users
grant execute on function public.match_kb_chunks(extensions.vector(384), int, float) to authenticated;
