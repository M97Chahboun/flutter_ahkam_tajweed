//! Tajweed Rules Processing Interface
//!
//! This module provides a simple interface for processing Quranic verses
//! using Tajweed rules for different recitation styles (Warsh and Hafs).

use tajweed_rules::{RecitationStyle, RuleMatch, TajweedProcessor};

/// Represents a Tajweed rule match with details
#[derive(Clone, Debug)]
pub struct TajweedRuleMatch {
    pub start_index: usize,
    pub end_index: usize,
    pub target_letter: String,
    pub following_letter: Option<String>,
    pub rule_arabic_name: String,
    pub rule_english_name: String,
    pub description: String,
    pub context: String,
    pub is_warsh_specific: bool,
    pub madd_length: Option<(u8, u8)>,
}

impl From<RuleMatch> for TajweedRuleMatch {
    fn from(m: RuleMatch) -> Self {
        TajweedRuleMatch {
            start_index: m.start_index,
            end_index: m.end_index,
            target_letter: m.target_letter.to_string(),
            following_letter: m.following_letter.map(|c| c.to_string()),
            rule_arabic_name: m.rule.arabic_name.to_owned(),
            rule_english_name: m.rule.english_name.to_owned(),
            description: m.rule.description_ar.to_owned(),
            context: m.context.clone(),
            is_warsh_specific: m.rule.warsh_specific,
            madd_length: m.rule.madd_length_warsh,
        }
    }
}

/// Recitation style enumeration for Flutter compatibility
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RecitationStyleType {
    Warsh,
    Hafs,
    Both,
}

/// Tajweed processor wrapper for Flutter integration
pub struct TajweedRulesProcessor {
    processor_warsh: TajweedProcessor,
    processor_hafs: TajweedProcessor,
}

/// Initialize the Tajweed Rules processor
#[flutter_rust_bridge::frb(sync)]
pub fn tajweed_rules_init() -> TajweedRulesProcessor {
    TajweedRulesProcessor {
        processor_warsh: TajweedProcessor::new(RecitationStyle::Warsh),
        processor_hafs: TajweedProcessor::new(RecitationStyle::Hafs),
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn process_verse_with_zwj(verse: String, processor: &TajweedRulesProcessor) -> String {
    processor.processor_warsh.process_verse_with_zwj(&verse)
}

/// Process a verse using the specified recitation style
#[flutter_rust_bridge::frb(sync)]
pub fn process_verse(
    verse: String,
    style: RecitationStyleType,
    processor_warsh: &TajweedRulesProcessor,
) -> Vec<TajweedRuleMatch> {
    match style {
        RecitationStyleType::Warsh => processor_warsh
            .processor_warsh
            .process_verse(&verse)
            .into_iter()
            .map(TajweedRuleMatch::from)
            .collect(),
        RecitationStyleType::Hafs => processor_warsh
            .processor_hafs
            .process_verse(&verse)
            .into_iter()
            .map(TajweedRuleMatch::from)
            .collect(),
        RecitationStyleType::Both => {
            let mut results = processor_warsh
                .processor_warsh
                .process_verse(&verse)
                .into_iter()
                .map(TajweedRuleMatch::from)
                .collect::<Vec<_>>();
            results.extend(
                processor_warsh
                    .processor_hafs
                    .process_verse(&verse)
                    .into_iter()
                    .map(TajweedRuleMatch::from),
            );
            results
        }
    }
}

/// Get app version
#[flutter_rust_bridge::frb(sync)]
pub fn get_version() -> String {
    tajweed_rules::VERSION.to_string()
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
