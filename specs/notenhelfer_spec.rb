require "#{File.dirname(__FILE__)}/spec_helper"

describe NotenHelfer do
  describe 'Noten können in Punkte usw. umgerechnet werden' do
    it 'Note in Punkte' do
      SchildErweitert::NotenHelfer.punkte_aus_note("4-").must_equal 4
      SchildErweitert::NotenHelfer.punkte_aus_note("1+").must_equal 15
      SchildErweitert::NotenHelfer.punkte_aus_note(nil).must_equal nil
    end

    it 'Punkte in Note' do
      SchildErweitert::NotenHelfer.note_aus_punkten("12").must_equal "2+"
      SchildErweitert::NotenHelfer.note_aus_punkten("2").must_equal "5"
      SchildErweitert::NotenHelfer.note_aus_punkten(nil).must_equal nil
      SchildErweitert::NotenHelfer.note_aus_punkten(5).must_equal "4"
      SchildErweitert::NotenHelfer.note_aus_punkten("17").must_equal nil
      SchildErweitert::NotenHelfer.note_aus_punkten("").must_equal nil
      SchildErweitert::NotenHelfer.note_aus_punkten("0").must_equal "6"
      SchildErweitert::NotenHelfer.note_aus_punkten("E3").must_equal nil
    end

    it 'Ziffernnote als String' do
      class N; include SchildErweitert::NotenHelfer; end
      n=N.new
      n.note_s("2+").must_equal "gut"
      n.note_s("3-").must_equal "befriedigend"
      n.note_s(nil).must_equal nil
      n.note_s("E3").must_equal "teilgenommen"
    end
  end
end


