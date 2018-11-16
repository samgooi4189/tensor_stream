RSpec.shared_examples "standard nn ops evaluator" do
  extend SupportedOp

  let(:ts) { TensorStream }

  before(:each) do
    TensorStream::Tensor.reset_counters
    TensorStream::Operation.reset_counters
    tf.reset_default_graph
    sess.clear_session_cache
  end

  supported_op ".conv2d" do
    context "rgb" do
      # 2 RGB images
      let(:image) do
        [
          [[[0.14, 0.47, 0.20], [0.96, 0.10, 0.59], [0.65, 0.954, 0.023], [0.9461, 0.52, 0.701]],
          [[0.83, 0.101, 0.21], [0.91, 0.87, 0.96], [0.30, 0.01, 0.07], [0.95, 0.81, 0.36]],
          [[0.07, 0.95, 0.84], [0.23, 0.22, 0.68], [0.017, 0.16, 0.67], [0.78, 0.33, 0.51]],
          [[0.13, 0.77, 0.54], [0.65, 0.34, 0.19], [0.601, 0.41, 0.31], [0.26, 0.33, 0.07]]],

          [[[0.1, 0.47, 0.20], [0.5, 0.10, 0.59], [0.65, 0.954, 0.1], [0.9461, 0.2, 0.3]],
          [[0.2, 0.101, 0.21], [0.9, 0.87, 0.96], [0.30, 0.01, 0.07], [0.95, 0.81, 0.36]],
          [[0.3, 0.95, 0.84], [0.23, 0.22, 0.68], [0.017, 0.2, 0.67], [0.1, 0.33, 0.8]],
          [[0.13, 0.77, 0.54], [0.65, 0.34, 0.19], [0.601, 0.41, 0.9], [0.26, 0.33, 0.1]]]
        ].t
      end

      let(:sample_filter) do
        [
         [[[0.97, 0.38, 0.62], [0.88, 0.16, 0.899], [0.87, 0.06, 0.06]], [[0.14, 0.47, 0.33], [0.83, 0.095, 0.04], [0.47, 0.16, 0.29]]],
         [[[0.79, 0.55, 0.24], [0.075, 0.84, 0.77], [0.40, 0.72, 0.55]], [[0.43, 0.05, 0.42], [0.16, 0.62, 0.31], [0.07, 0.94, 0.99]]]
        ].t
      end

      it "calculates for convultion on a 2d image" do
        conv = ts.nn.conv2d(image, sample_filter, [1, 1, 1, 1], 'SAME')
        expect(image.shape.shape).to eq([2, 4, 4, 3])
        expect(sample_filter.shape.shape).to eq([2, 2, 3, 3])
        expect(conv.shape.shape).to eq([2, 4, 4, 3])
        result = sess.run(conv)
        expect(tr(result)).to eq([
          [
            [
              [2.5631, 2.8753, 3.008], [3.7298, 2.8255, 2.5945], [3.2126, 2.1191, 2.923], [2.9404, 1.9469, 2.1458]
            ],
            [
              [3.0216, 3.2365, 3.2798], [3.1167, 2.2265, 2.8423], [2.0525, 2.05, 2.0801], [2.7925, 1.5856, 2.0606]
            ],
            [
              [2.8928, 1.9958, 2.7173], [2.4191, 1.6493, 1.7962], [2.162, 1.7334, 1.5243], [1.7489, 0.8504, 1.1659]
            ],
            [
              [1.736, 0.5732, 1.0884], [1.6651, 0.6838, 1.0247], [1.5567, 0.4773, 0.8791], [0.6035, 0.1558, 0.4621]
            ]
          ],
          [
            [
              [1.9579, 2.2969, 2.676], [3.3119, 2.6575, 2.3293], [2.8255, 2.0292, 2.7986], [2.31, 1.8716, 1.8341]
            ],
            [
              [2.5908, 3.1189, 2.9411], [3.1134, 2.2475, 2.8485], [1.7834, 2.3222, 2.1124], [2.3713, 1.4204, 2.0569]
            ],
            [
              [3.1159, 2.0832, 2.86], [2.4936, 2.2077, 2.3819], [2.4764, 1.9196, 1.7742], [1.3536, 0.631, 0.7782]
            ],
            [
              [1.736, 0.5732, 1.0884], [1.9424, 0.7782, 1.1958], [2.0841, 0.5175, 0.9232], [0.6296, 0.1576, 0.4639]
            ]
          ]
        ])
      end

      specify "gradients" do
        conv = ts.nn.conv2d(image, sample_filter, [1, 1, 1, 1], 'SAME')
        g = ts.gradients(conv, [image, sample_filter])
        result = sess.run(g)

        expect(tr(result)).to eq([
          [
            [
              [[1.97, 1.939, 0.99], [2.91, 2.904, 1.91], [2.91, 2.904, 1.91], [2.91, 2.904, 1.91]],
              [[3.55, 3.624, 2.66], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58]],
              [[3.55, 3.624, 2.66], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58]],
              [[3.55, 3.624, 2.66], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58]]
            ],
            [
              [[1.97, 1.939, 0.99], [2.91, 2.904, 1.91], [2.91, 2.904, 1.91], [2.91, 2.904, 1.91]],
              [[3.55, 3.624, 2.66], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58]],
              [[3.55, 3.624, 2.66], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58]],
              [[3.55, 3.624, 2.66], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58], [5.39, 5.679, 5.58]]
            ]
          ],
          [
            [
              [[15.2582, 15.2582, 15.2582], [14.41, 14.41, 14.41], [14.434, 14.434, 14.434]], 
              [[13.3582, 13.3582, 13.3582], [9.828, 9.828, 9.828], [10.854, 10.854, 10.854]]
            ],
            [
              [[10.366, 10.366, 10.366], [10.642, 10.642, 10.642], [11.73, 11.73, 11.73]],
              [[8.706, 8.706, 8.706], [7.0, 7.0, 7.0], [8.55, 8.55, 8.55]]
            ]
          ]
        ])
      end
    end

    context "grayscale" do
      let(:image) do
        [
          [
            [[0.92], [0.58], [0.62], [0.98]],
            [[0.61], [0.56], [0.08], [0.99]],
            [[0.98], [0.18], [0.031], [0.74]],
            [[0.769], [0.79], [0.42], [0.057]]
          ],
          [
            [[0.63], [0.62], [0.10], [0.83]],
            [[0.808], [0.44], [0.67], [0.12]],
            [[0.21], [0.52], [0.19], [0.40]],
            [[0.04], [0.37], [0.51], [0.75]]
          ]
        ].t
      end

      let(:sample_filter) do
          [
            [[ [1.0] ], [ [0.5] ]],
            [[ [0.0] ], [ [0.2] ]],
          ].t
      end

      let(:sample_filter_2) do
        [
          [[ [1.0, 1.0] ], [ [0.5, 1.0] ]],
          [[ [0.0, 0.0] ], [ [0.2, 0.1] ]],
        ].t
    end

      specify do
        expect(image.shape.shape).to eq([2, 4, 4, 1])
        expect(sample_filter.shape.shape).to eq([2, 2, 1, 1])
        conv = ts.nn.conv2d(image, sample_filter, [1, 1, 1, 1], 'SAME')
        expect(conv.shape.shape).to eq([2, 4, 4, 1])
        result = sess.run(conv)

        expect(tr(result)).to eq([
          [
            [[1.322], [0.906], [1.308], [0.98]],
            [[0.926], [0.6062], [0.723], [0.99]],
            [[1.228], [0.2795], [0.4124], [0.74]],
            [[1.164], [1.0], [0.4485], [0.057]]
          ],
          [
            [[1.028], [0.804], [0.539], [0.83]],
            [[1.132], [0.813], [0.81], [0.12]],
            [[0.544], [0.717], [0.54], [0.4]],
            [[0.225], [0.625], [0.885], [0.75]]]
          ])

        conv = ts.nn.conv2d(image, sample_filter_2, [1, 1, 1, 1], 'SAME')
        result = sess.run(conv)
        expect(result.shape).to eq([2, 4, 4, 2])

        expect(tr(result)).to eq([
          [[[1.322, 1.556], [0.906, 1.208], [1.308, 1.699], [0.98, 0.98]],
           [[0.926, 1.188], [0.6062, 0.6431], [0.723, 1.144], [0.99, 0.99]],
          [[1.228, 1.239], [0.2795, 0.253], [0.4124, 0.7767], [0.74, 0.74]],
          [[1.164, 1.559], [1.0, 1.21], [0.4485, 0.477], [0.057, 0.057]]],
         [[[1.028, 1.294], [0.804, 0.787], [0.539, 0.942], [0.83, 0.83]],
          [[1.132, 1.3], [0.813, 1.129], [0.81, 0.83], [0.12, 0.12]],
          [[0.544, 0.767], [0.717, 0.761], [0.54, 0.665], [0.4, 0.4]],
          [[0.225, 0.41], [0.625, 0.88], [0.885, 1.26], [0.75, 0.75]]]])
      end

      specify "gradient" do
        conv = ts.nn.conv2d(image, sample_filter, [1, 1, 1, 1], 'SAME')
        g = tf.gradients(conv, [image, sample_filter])
        result = sess.run(g)
        expect(tr(result)).to eq([
          [
            [
              [[1.0],[1.5],[1.5],[1.5]],
              [[1.0 ],[1.7],[1.7],[1.7]],
              [[1.0 ],[1.7],[1.7],[1.7]],
              [[1.0 ],[1.7],[1.7],[1.7]]
            ],
            [
              [[1.0 ],[1.5],[1.5],[1.5]],
              [[1.0 ],[1.7],[1.7],[1.7]],
              [[1.0 ],[1.7],[1.7],[1.7]],
              [[1.0 ],[1.7],[1.7],[1.7]]
            ]
          ],
          [
            [
              [[16.515]],[[11.548]]
            ],
            [
              [[11.235]],[[ 7.818]]
            ]
          ]
        ])

        conv = ts.nn.conv2d(image, sample_filter_2, [1, 1, 1, 1], 'SAME')
        g = tf.gradients(conv, [image, sample_filter_2])
        result = sess.run(g)
 
        expect(tr(result)).to eq([
          [
            [
              [[2.0], [3.5], [3.5], [3.5]],
              [[2.0], [3.8], [3.8], [3.8]],
              [[2.0], [3.8], [3.8], [3.8]],
              [[2.0], [3.8], [3.8], [3.8]]
            ],
            [
              [[2.0], [3.5], [3.5], [3.5]],
              [[2.0], [3.8], [3.8], [3.8]],
              [[2.0], [3.8], [3.8], [3.8]],
              [[2.0], [3.8], [3.8], [3.8]]
            ]
          ],
          [
            [
              [[16.515, 16.515]],
              [[11.548, 11.548]]
            ],
            [
              [[11.235, 11.235]],
              [[7.818, 7.818]]
            ]
          ]
        ])
      end
    end
  end
end