# JDK8 流

> 流是 Java 中一种新的数据处理方式，基于函数式接口，函数式接口又对应lambda表达式和方法引用两种使用方式。

```java
public class StreamTest {

    public static void main(String[] args) {
        List<Product> list = new ArrayList<>();
        list.add(new Product("五粮液", 1L));
        List<String> nameList = list
                // streamPipeline（ReferencePipeline.Head）
                .stream()
                // filterPipeline（StatelessOp）
                .filter(i -> i.getPrice() >= 100)
                // mapPipeline（StatelessOp）
                .map(Product::getName)
                // sortedPipeline（OfRef extends StatefulOp）
                .sorted(String::compareTo)
                // TerminalOp
                .collect(Collectors.toList());
        // Pipeline链
        // sortedPipeline -> mapPipeline -> filterPipeline -> streamPipeline -> sourceSpliterator -> collection
        // 中间阶段           中间阶段         中间阶段           来源阶段           来源迭代/分片器         集合
        // sortedPipeline.evaluate(TerminalOp) Pipeline管道终结操作
        // TerminalOp.evaluateSequential(sortedPipeline, Spliterator)
        // sortedPipeline.wrapAndCopyInto()
        // sortedPipeline.wrapSink() 构建Sink链 ReferencePipeline.opWrapSink()生成Sink
        // filterSink -> mapSink -> sortedSink -> collectSink
        // sortedPipeline.copyInto()
        //     sink.begin()
        //     Spliterator.forEachRemaining(sink) 遍历collection集合中元素，sink链处理元素
        //     sink.end()
        // collectSink.get() 获取最终结果
    }

    private static class Product {

        private final String name;

        private final Long price;

        public Product(String name, Long price) {
            this.name = name;
            this.price = price;
        }

        public String getName() {
            return name;
        }

        public Long getPrice() {
            return price;
        }

    }

}
```

## stream()

```java
public static <T> Stream<T> stream(Spliterator<T> spliterator, boolean parallel) {
    return new ReferencePipeline.Head<>(spliterator,
            StreamOpFlag.fromCharacteristics(spliterator),
            parallel);
}
```

## filter()

```java
public final Stream<P_OUT> filter(Predicate<? super P_OUT> predicate) {
    return new ReferencePipeline.StatelessOp<P_OUT, P_OUT>(this, StreamShape.REFERENCE,
            StreamOpFlag.NOT_SIZED) {

        @Override
        Sink<P_OUT> opWrapSink(int flags, Sink<P_OUT> sink) {
            return new Sink.ChainedReference<P_OUT, P_OUT>(sink) {
                @Override
                public void begin(long size) {
                    downstream.begin(-1);
                }

                @Override
                public void accept(P_OUT u) {
                    if (predicate.test(u))
                        downstream.accept(u);
                }
            };
        }

    };
}
```

## map()

```java
public final <R> Stream<R> map(Function<? super P_OUT, ? extends R> mapper) {
    return new ReferencePipeline.StatelessOp<P_OUT, R>(this, StreamShape.REFERENCE,
            StreamOpFlag.NOT_SORTED | StreamOpFlag.NOT_DISTINCT) {

        @Override
        Sink<P_OUT> opWrapSink(int flags, Sink<R> sink) {
            return new Sink.ChainedReference<P_OUT, R>(sink) {
                @Override
                public void accept(P_OUT u) {
                    downstream.accept(mapper.apply(u));
                }
            };
        }

    };
}
```

## sorted()

```java
private static final class OfRef<T> extends ReferencePipeline.StatefulOp<T, T> {

    @Override
    public Sink<T> opWrapSink(int flags, Sink<T> sink) {
        if (StreamOpFlag.SORTED.isKnown(flags) && isNaturalSort)
            return sink;
        else if (StreamOpFlag.SIZED.isKnown(flags))
            return new SortedOps.SizedRefSortingSink<>(sink, comparator);
        else
            return new SortedOps.RefSortingSink<>(sink, comparator);
    }

}

private static final class RefSortingSink<T> extends SortedOps.AbstractRefSortingSink<T> {

    private ArrayList<T> list;

    RefSortingSink(Sink<? super T> sink, Comparator<? super T> comparator) {
        super(sink, comparator);
    }

    @Override
    public void begin(long size) {
        if (size >= Nodes.MAX_ARRAY_SIZE) throw new IllegalArgumentException(Nodes.BAD_SIZE);
        list = (size >= 0) ? new ArrayList<>((int) size) : new ArrayList<>();
    }

    @Override
    public void end() {
        list.sort(comparator);
        downstream.begin(list.size());
        if (!cancellationRequestedCalled) {
            list.forEach(downstream::accept);
        } else {
            for (T t : list) {
                if (downstream.cancellationRequested()) break;
                downstream.accept(t);
            }
        }
        downstream.end();
        list = null;
    }

    @Override
    public void accept(T t) {
        list.add(t);
    }

}
```

## Collectors.toList()

```java
public static <T> Collector<T, ?, List<T>> toList() {
    return new Collectors.CollectorImpl<>(ArrayList::new,
            List::add,
            (left, right) -> {
                left.addAll(right);
                return left;
            },
            CH_ID);
}

public static <T, I> TerminalOp<T, I> makeRef(Collector<? super T, I, ?> collector) {
        Supplier<I> supplier = Objects.requireNonNull(collector).supplier();
        BiConsumer<I, ? super T> accumulator = collector.accumulator();
        BinaryOperator<I> combiner = collector.combiner();

    class ReducingSink extends ReduceOps.Box<I> implements ReduceOps.AccumulatingSink<T, I, ReducingSink> {
        @Override
        public void begin(long size) {
            state = supplier.get();
        }
    
        @Override
        public void accept(T t) {
            accumulator.accept(state, t);
        }
    
        @Override
        public void combine(ReducingSink other) {
            state = combiner.apply(state, other.state);
        }
    }

    return new ReduceOps.ReduceOp<T, I, ReducingSink>(StreamShape.REFERENCE) {
        // ...
    };
}
```

## collect()

```java
public <P_IN> R evaluateSequential(PipelineHelper<T> helper, Spliterator<P_IN> spliterator) {
    return helper.wrapAndCopyInto(makeSink(), spliterator).get();
}

final <P_IN, S extends Sink<E_OUT>> S wrapAndCopyInto(S sink, Spliterator<P_IN> spliterator) {
    copyInto(wrapSink(Objects.requireNonNull(sink)), spliterator);
    return sink;
}

final <P_IN> Sink<P_IN> wrapSink(Sink<E_OUT> sink) {
    for (AbstractPipeline p = AbstractPipeline.this; p.depth > 0; p = p.previousStage) {
        sink = p.opWrapSink(p.previousStage.combinedFlags, sink);
    }
    return (Sink<P_IN>) sink;
}

final <P_IN> void copyInto(Sink<P_IN> wrappedSink, Spliterator<P_IN> spliterator) {
    if (!StreamOpFlag.SHORT_CIRCUIT.isKnown(getStreamAndOpFlags())) {
        wrappedSink.begin(spliterator.getExactSizeIfKnown());
        spliterator.forEachRemaining(wrappedSink);
        wrappedSink.end();
    } else {
        copyIntoWithCancel(wrappedSink, spliterator);
    }
}
```
