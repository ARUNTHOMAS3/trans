const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

async function testSearch() {
  const query = '2.00% w/w';
  const type = 'strengths';
  const table = 'strengths';
  const field = 'strength_name';

  console.log(`Searching for "${query}" in ${table}.${field}...`);
  
  const { data, error } = await supabase
    .from(table)
    .select('*')
    .ilike(field, `%${query}%`)
    .eq('is_active', true)
    .limit(20);

  if (error) {
    console.error('Error:', error);
  } else {
    console.log(`Results (${data.length}):`);
    data.forEach(row => {
      console.log(`ID: ${row.id} | ${field}: ${row[field]}`);
    });
  }

  // Also try with * wildcard
  const queryStar = `*${query.replace(/%/g, '*') }*`;
  console.log(`\nSearching with stars: "${queryStar}"...`);
  const { data: dataStar, error: errorStar } = await supabase
    .from(table)
    .select('*')
    .ilike(field, queryStar)
    .eq('is_active', true)
    .limit(20);

  if (errorStar) {
    console.error('Star Error:', errorStar);
  } else {
    console.log(`Star Results (${dataStar.length}):`);
    dataStar.forEach(row => {
      console.log(`ID: ${row.id} | ${field}: ${row[field]}`);
    });
  }
}

testSearch();
