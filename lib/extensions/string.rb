class String
  def downcase_first
    self.sub(/\S/, &:downcase)
  end
end
