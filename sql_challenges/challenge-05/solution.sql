-- try it 1
select colour from my_brick_collection
union
select colour from your_brick_collection
order by colour;

select shape from my_brick_collection
union all
select shape from your_brick_collection
order by shape;

-- try it 2

select shape from my_brick_collection
minus
select shape from your_brick_collection;

select colour from my_brick_collection
intersect
select colour from your_brick_collection
order by colour;